import sys
import os
from logging.config import dictConfig

import bcrypt
from flask import redirect, render_template, request, Flask
from flask_login import current_user, login_user, login_required
from flask_login import LoginManager, UserMixin
from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, SubmitField
from wtforms.validators import DataRequired

from app import app
from models.glsa import GLSA
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


@app.route('/drafts')
@login_required
def drafts():
    return render_template('drafts.html')


@app.route('/new')
@login_required
def new():
    return render_template('new.html')


@app.route('/')
@app.route('/archive')
@login_required
def archive():
    # TODO: paginate
    glsas = GLSA.query.order_by(GLSA.glsa_id).all()
    return render_template('archive.html', glsas=glsas)


@app.route('/glsa/<glsa_id>')
@login_required
def glsa(glsa_id):
    advisory = GLSA.query.filter_by(glsa_id=glsa_id).first()
    if not advisory:
        return render_template('glsa.html'), 404
    return render_template('glsa.html', glsa=advisory)
