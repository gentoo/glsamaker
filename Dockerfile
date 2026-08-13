FROM gentoo/python

WORKDIR /var/lib/glsamaker

COPY . /var/lib/glsamaker

RUN emerge-webrsync --quiet
RUN emerge --quiet --getbinpkg --jobs=0 dev-python/pip
RUN rm /usr/lib/python/EXTERNALLY-MANAGED
RUN --mount=type=cache,target=/root/.cache/pip pip install .

EXPOSE 8080

CMD /var/lib/glsamaker/glsamaker/main.py
