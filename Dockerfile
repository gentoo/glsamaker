FROM python:3.9-bullseye

WORKDIR /var/lib/glsamaker

COPY . /var/lib/glsamaker

RUN --mount=type=cache,target=/root/.cache/pip pip install .

EXPOSE 8080

CMD /var/lib/glsamaker/glsamaker/main.py
