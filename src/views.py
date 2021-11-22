import datetime
import sys
import os
import uuid
from logging.config import dictConfig

from flask import redirect, render_template, request, Flask
from flask_login import LoginManager, UserMixin
from flask_login import current_user, login_user, login_required
from flask_wtf import FlaskForm
from pkgcore.ebuild.atom import atom
from sqlalchemy import desc
from wtforms import SelectField, StringField, TextAreaField, PasswordField, SubmitField, HiddenField, Field
from wtforms.validators import DataRequired
import bcrypt

from app import app, db
from models.bug import Bug
from models.glsa import GLSA
from models.package import Affected
from models.reference import Reference
from models.user import User, uid_to_nick

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
    impact = StringField('Impact', validators=[DataRequired()])
    impact_type = SelectField('Impact Type', choices=['low', 'normal', 'high'])
    workaround = TextAreaField('Workaround', validators=[DataRequired()])
    resolution = TextAreaField('Resolution', validators=[DataRequired()])
    resolution_code = TextAreaField('Resolution Code',
                                    validators=[DataRequired()])
    references = StringField('References', validators=[DataRequired()])
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
                app.logger.info("Successful login for '{}'".format(username))
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

    form = GLSAForm(title=glsa.title, synopsis=glsa.synopsis,
                    product_type=glsa.product_type,
                    bugs=', '.join([bug.bug_id for bug in glsa.bugs]),
                    access=glsa.access,
                    background=glsa.background,
                    description=glsa.description, impact=glsa.impact,
                    impact_type=glsa.impact_type,
                    workaround=glsa.workaround,
                    resolution=glsa.resolution,
                    resolution_code=glsa.resolution_code,
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
        glsa.background = form.background.data
        glsa.description = form.description.data
        glsa.impact = form.impact.data
        glsa.impact_type = form.impact_type.data
        glsa.workaround = form.workaround.data
        glsa.resolution = form.resolution.data
        glsa.resolution_code = form.resolution_code.data
        glsa.references = [Reference.new(text.strip())
                           for text in form.references.data.split(', ')]
        glsa.submitted_time = datetime.datetime.now()
        glsa.draft = True
        db.session.merge(glsa)
        db.session.commit()
        return drafts()

    return render_template('edit_glsa.html', form=form, glsa=glsa, new=True)


@app.route('/archive')
@login_required
def archive():
    # TODO: paginate
    glsas = GLSA.query.order_by(GLSA.glsa_id).all()
    return render_template('archive.html', glsas=glsas)


@app.route('/glsa/<glsa_id>')
@login_required
def show_glsa(glsa_id):
    advisory = GLSA.query.filter_by(glsa_id=glsa_id).first()
    if not advisory:
        return render_template('glsa.html'), 404
    return render_template('glsa.html', glsa=advisory)
