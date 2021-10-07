import sys
import os
from logging.config import dictConfig

import bcrypt
from flask import redirect, render_template, Flask
from flask_login import current_user, login_user, login_required, LoginManager, UserMixin
from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, SubmitField
from wtforms.validators import DataRequired

from db import User

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

app = Flask(__name__)
app.config['SECRET_KEY'] = os.urandom(32)
app.config['SQLALCHEMY_DATABASE_URI'] = "postgresql://root:root@db/postgres"
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

login_manager = LoginManager()
login_manager.init_app(app)


class LoginForm(FlaskForm):
    username = StringField('Username', validators=[DataRequired()])
    password = PasswordField('Password', validators=[DataRequired()])
    submit = SubmitField('Sign In')


@app.route('/login', methods=['GET', 'POST'])
def login():
    form = LoginForm()
    if form.validate_on_submit():
        username = form.username.data
        password = form.password.data
        user = User.query.filter_by(nick=username).first()
        if user:
            if bcrypt.checkpw(password.encode('utf-8'),
                              user.password.encode('utf-8')):
                login_user(user)
                return redirect('/')
            app.logger.info(
                "Login attempt for '{}' with bad password".format(username))
            return render_template('login.html', form=form, error=True)
        else:
            app.logger.info(
                "Login attempt from unknown user '{}'".format(form.user))
    return render_template('login.html', form=form)


@app.route('/')
@login_required
def hello():
    return "Hello World, {}!!\n".format(current_user.nick)


@login_manager.user_loader
def load_user(user_id):
    return User.query.filter_by(id=user_id).first()


@login_manager.unauthorized_handler
def unauthorized():
    return redirect('/login')
