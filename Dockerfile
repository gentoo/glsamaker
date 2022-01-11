FROM python:3.9-bullseye

WORKDIR /var/lib/glsamaker

RUN git clone https://anongit.gentoo.org/git/data/glsa.git

COPY . /var/lib/glsamaker

RUN pip install .

EXPOSE 8080

CMD /var/lib/glsamaker/glsamaker/main.py
