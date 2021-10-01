FROM python:3.9-bullseye

RUN pip install flask flask_login flask_wtf flask_sqlalchemy wtforms sqlalchemy psycopg2 py-bcrypt

WORKDIR /var/lib/glsamaker

COPY . /var/lib/glsamaker

EXPOSE 8080

CMD /var/lib/glsamaker/src/run.py
