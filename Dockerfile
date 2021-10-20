FROM python:3.9-bullseye

WORKDIR /var/lib/glsamaker

RUN git clone https://anongit.gentoo.org/git/data/glsa.git

# Install dependencies on their own so we don't have to reinstall
# every time we change anything in the source tree
COPY pyproject.toml /var/lib/glsamaker
COPY setup.cfg /var/lib/glsamaker
RUN pip install .

COPY . /var/lib/glsamaker

EXPOSE 8080

CMD /var/lib/glsamaker/src/glsamaker.py
