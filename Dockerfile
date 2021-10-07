FROM python:3.9-bullseye

WORKDIR /var/lib/glsamaker

COPY . /var/lib/glsamaker

RUN pip install .

EXPOSE 8080

CMD /var/lib/glsamaker/src/run.py
