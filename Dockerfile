FROM python:3.9-bullseye

RUN pip install flask flask-login wtforms

WORKDIR /var/lib/glsamaker

COPY . /var/lib/glsamaker

EXPOSE 8080

CMD /var/lib/glsamaker/src/run.py
