FROM golang:1.14.0 AS builder
WORKDIR /go/src/glsamaker
COPY . /go/src/glsamaker
RUN go get github.com/go-pg/pg/v9
RUN go get github.com/google/uuid
RUN go get github.com/skip2/go-qrcode
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -o bin .

FROM node:13 AS assetsbuilder
WORKDIR /go/src/glsamaker
COPY . /go/src/glsamaker
RUN npm install && cd node_modules/@gentoo/tyrian && npm install && npm run dist && cd /go/src/glsamaker
RUN npx webpack

FROM alpine:latest as certs
RUN apk --update add ca-certificates

FROM scratch
WORKDIR /go/src/glsamaker
COPY --from=certs /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=assetsbuilder /go/src/glsamaker/assets /go/src/glsamaker/assets
COPY --from=builder /go/src/glsamaker/bin /go/src/glsamaker/bin
COPY --from=builder /go/src/glsamaker/pkg /go/src/glsamaker/pkg
COPY --from=builder /go/src/glsamaker/web /go/src/glsamaker/web

CMD ["/go/src/glsamaker/bin/glsamaker"]
