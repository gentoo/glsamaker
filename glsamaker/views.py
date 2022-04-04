from datetime import datetime, date
import uuid
from logging.config import dictConfig

from flask import redirect, render_template, request, Response
from flask_login import LoginManager
from flask_login import current_user, login_user, login_required
from flask_wtf import FlaskForm
from pkgcore.ebuild.atom import atom
from sqlalchemy import desc
from wtforms import BooleanField, SelectField, StringField, TextAreaField, PasswordField, SubmitField
from wtforms.validators import DataRequired
import bcrypt

from glsamaker.autoglsa import autogenerate_glsa, bugs_aliases
from glsamaker.app import app, bgo, config, db
from glsamaker.models.bug import Bug
from glsamaker.models.glsa import GLSA
from glsamaker.models.package import Affected
from glsamaker.models.reference import Reference
from glsamaker.models.user import User, uid_to_nick
from glsamaker.release import release_email, release_xml, generate_mail, generate_xml

dictConfig({
    'version': 1,
    'formatters': {'default': {
        'format': '[%(asctime)s] %(levelname)s in %(module)s: %(message)s',
    }},
    'handlers': {'wsgi': {
        'class': 'logging.StreamHandler',
        'stream': 'ext://sys.stdout',
        'formatter': 'default'
    }},
    'root': {
        'level': 'INFO',
        'handlers': ['wsgi']
    }
})

login_manager = LoginManager()
login_manager.init_app(app)


# Terrible hack to allow uid_to_nick to be accessible in jinja
# templates so we can use it in places like archive.html
app.jinja_env.globals.update(uid_to_nick=uid_to_nick)


class LoginForm(FlaskForm):
    username = StringField('Username', validators=[DataRequired()])
    password = PasswordField('Password', validators=[DataRequired()])
    submit = SubmitField('Sign In')


class GLSAForm(FlaskForm):
    title = StringField('Title', validators=[DataRequired()])
    synopsis = StringField('Synopsis', validators=[DataRequired()])
    # TODO: validators
    product_type = SelectField('Product Type',
                               choices=['ebuild', 'infrastructure'])
    bugs = StringField('Bugs', validators=[])
    access = SelectField('Access',
                         choices=['remote', 'local', 'local and remote'])
    background = TextAreaField('Background', validators=[DataRequired()])
    description = TextAreaField('Description', validators=[DataRequired()])
    impact = TextAreaField('Impact', validators=[DataRequired()])
    impact_type = SelectField('Impact Type', choices=['normal', 'low', 'high'])
    workaround = TextAreaField('Workaround', validators=[DataRequired()])
    resolution = TextAreaField('Resolution', validators=[DataRequired()])
    references = StringField('References', validators=[])
    release = BooleanField('Release')
    ack = BooleanField('Ack')
    submit = SubmitField('Submit')


class BugForm(FlaskForm):
    bugs = StringField('Bugs')
    submit = SubmitField('Submit')


@login_manager.user_loader
def load_user(user_id):
    return User.query.filter_by(id=user_id).first()


@login_manager.unauthorized_handler
def unauthorized():
    return redirect('/login')


@app.route('/login', methods=['GET', 'POST'])
def login():
    form = LoginForm()
    if form.validate_on_submit():
        username = form.username.data
        password = form.password.data
        user = User.query.filter_by(nick=username).first()
        if user and user.password:
            if bcrypt.checkpw(password.encode('utf-8'),
                              user.password.encode('utf-8')):
                # Success, so login user and redirect to homepage
                login_user(user)
                app.logger.info("Successful login for '{}', id '{}'".format(username, user.id))
                return redirect('/')
            # Otherwise, return a generic error message to the user,
            # but log exactly what happened
            app.logger.info(
                "Login attempt for '{}' with bad password".format(username))
        elif not user:
            app.logger.info(
                "Login attempt from unknown user '{}'".format(username))
        elif not user.password:
            app.logger.info(
                "Login attempt for passwordless user '{}'".format(username))
        else:
            app.logger.info("Unexpected error in login")
            app.logger.info("User: {}".format(username))
            app.logger.info("Password: {}".format(password))
            app.logger.info("User query: {}".format(user))

    if request.method == 'POST':
        return render_template('login.html', form=form, error=True)
    return render_template('login.html', form=form)


@app.route('/')
@app.route('/drafts')
@login_required
def drafts():
    glsas = GLSA.query.filter_by(draft=True).order_by(desc(GLSA.submitted_time))
    return render_template('drafts.html', glsas=glsas)


def parse_atoms(request, range_type):
    ret = []
    # TODO: these need to be properly in the flask form for proper
    # validation, but flask forms with lists is hard
    atoms = request.form.getlist('{}[]'.format(range_type))
    arches = request.form.getlist('{}_arch[]'.format(range_type))
    for pkg, arch in zip(atoms, arches):
        pkg = pkg.strip()
        arch = arch.strip()
        if pkg != '' and arch != '':
            package = atom(pkg)
            pn = str(package.unversioned_atom)
            # Silly hack to get the range type chars at the front of
            # the string
            pkg_range = Affected.range_types[pkg.replace(package.cpvstr, '')]
            version = package.fullver
            slot = package.slot or '*'
            ret.append(Affected(pn, version, pkg_range, arch, slot,
                                range_type))
    return ret


@app.route('/edit_glsa', methods=['GET', 'POST'])
@app.route('/edit_glsa/<glsa_id>', methods=['GET', 'POST'])
@login_required
def edit_glsa(glsa_id=None):
    if not glsa_id:
        glsa = GLSA()
        glsa.glsa_id = str(uuid.uuid4())
        glsa.requester = current_user.id
    else:
        glsa = GLSA.query.filter_by(glsa_id=glsa_id).first()
        # No editing released advisories for now
        if not glsa.draft:
            return redirect('/drafts'), 400

    form = GLSAForm(title=glsa.title, synopsis=glsa.synopsis,
                    product_type=glsa.product_type,
                    bugs=', '.join([bug.bug_id for bug in glsa.bugs]),
                    access=glsa.access,
                    background=glsa.background,
                    description=glsa.description, impact=glsa.impact,
                    impact_type=glsa.impact_type,
                    workaround=glsa.workaround,
                    resolution=glsa.resolution,
                    references=', '.join(
                        [ref.ref_text for ref in glsa.references]))

    if form.validate_on_submit() and request.method == 'POST':
        glsa.title = form.title.data
        glsa.synopsis = form.synopsis.data
        glsa.product_type = form.product_type.data
        glsa.bugs = [Bug.new(bug.strip()) for bug in form.bugs.data.split(',')]
        glsa.access = form.access.data
        glsa.affected = parse_atoms(request, 'unaffected') + \
            parse_atoms(request, 'vulnerable')
        glsa.product = ','.join(sorted([cpn.split('/')[1]
                                        for cpn in glsa.get_pkgs()]))
        glsa.background = form.background.data
        glsa.description = form.description.data
        glsa.impact = form.impact.data
        glsa.impact_type = form.impact_type.data
        glsa.workaround = form.workaround.data
        glsa.resolution = form.resolution.data

        # There may already be references, but the references we
        # already have might also be bug aliases. Use list() and set()
        # hackery to ensure list uniqueness
        alias_refs = list(set(bugs_aliases([bug.bug_id for bug in glsa.bugs])))
        glsa.references = list(set([Reference.new(text.strip())
                                    for text in (form.references.data.split(', ') + alias_refs)
                                    if text.strip()]))
        glsa.requested_time = datetime.now()

        # Release it!
        if form.release.data:
            glsa.glsa_id = GLSA.next_id()
            glsa.draft = False
            glsa.submitter = current_user.id
            glsa.submitted_time = datetime.now()
            glsa.announced = date.today()
            glsa.revision_count = 1

            # Yes, it's a bit weird, but it's what has been done in the past
            # The first revision is made on the date the GLSA is announced.
            glsa.revised_date = glsa.announced

            app.logger.info(config['glsamaker'])
            app.logger.info(config['glsamaker']['autorelease'])
            if 'glsamaker' in config and \
               'autorelease' in config['glsamaker'] and \
               config['glsamaker']['autorelease'] == 'yes':
                release_email(glsa)
                release_xml(glsa)
            else:
                app.logger.info("Autorelease disabled, not automatically adding XML or sending email")
            db.session.commit()
            return redirect('/glsa/' + glsa.glsa_id)
        elif form.ack.data:
            glsa.acked_by = current_user.id
        else:
            glsa.draft = True
            db.session.add(glsa)
        db.session.commit()
        return redirect('/drafts')

    if glsa_id:
        return render_template('edit_glsa.html', form=form, glsa=glsa,
                               current_user=current_user)
    return render_template('edit_glsa.html', form=form, glsa=glsa,
                           current_user=current_user, new=True)


@app.route('/newbugs', methods=['GET', 'POST'])
@login_required
def newbugs():
    form = BugForm()
    if request.method == 'GET':
        return render_template('newbugs.html', form=form)
    elif request.method == 'POST' and form.validate_on_submit():
        bugs = [int(bug) for bug in form.bugs.data.split(',')]
        try:
            glsa = autogenerate_glsa(bgo.getbugs(bugs))
            glsa.requester = current_user.id
            db.session.add(glsa)
            db.session.commit()
            return redirect('/edit_glsa/{}'.format(glsa.glsa_id))
        except:
            # TODO: catch failures from glsa generation
            raise


@app.route('/archive')
@login_required
def archive():
    # TODO: paginate
    glsas = GLSA.query.filter_by(draft=False).order_by(GLSA.glsa_id).all()
    return render_template('archive.html', glsas=glsas)


@app.route('/glsa/<glsa_id>')
@login_required
def show_glsa(glsa_id):
    advisory = GLSA.query.filter_by(glsa_id=glsa_id).first()
    if not advisory:
        return render_template('glsa.html'), 404
    return render_template('glsa.html', glsa=advisory)

@app.route('/glsa/<glsa_id>/mail')
@login_required
def glsa_mail(glsa_id):
    advisory = GLSA.query.filter_by(glsa_id=glsa_id).first()
    if not advisory or not advisory.announced:
        return redirect('/'), 400
    mail = generate_mail(advisory, date=datetime.now().strftime('%a, %d %b %Y %X'))
    return Response(mail, mimetype='text/plain',
                    headers={"Content-disposition":
                             "attachment; filename=glsa-{}.mail".format(advisory.glsa_id)})

@app.route('/glsa/<glsa_id>/xml')
@login_required
def glsa_xml(glsa_id):
    advisory = GLSA.query.filter_by(glsa_id=glsa_id).first()
    if not advisory or not advisory.announced:
        return redirect('/'), 400
    return Response(generate_xml(advisory), mimetype='text/plain',
                    headers={"Content-disposition":
                             "attachment; filename=glsa-{}.xml".format(advisory.glsa_id)})
