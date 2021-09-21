#!/usr/bin/env python3

import os

from flask import current_app, render_template, redirect, Flask
from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, SubmitField
from wtforms.validators import DataRequired


app = Flask(__name__)
app.config['SECRET_KEY'] = os.urandom(32)


class LoginForm(FlaskForm):
    username = StringField('Username', validators=[DataRequired()])
    password = PasswordField('Password', validators=[DataRequired()])
    submit = SubmitField('Sign In')


@app.route('/login', methods=['GET', 'POST'])
def login():
    form = LoginForm()
    return render_template('login.html', form=form)


@app.route("/")
def hello():
    return "Hello World!!\n"


if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8080)
