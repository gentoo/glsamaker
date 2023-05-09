from flask_login import LoginManager
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.orm import declarative_base

login_manager = LoginManager()
db = SQLAlchemy()
base = declarative_base()
