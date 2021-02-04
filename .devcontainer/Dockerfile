ARG STRUCTURIZR_VERSION=1.8.0

FROM alpine:3.13 as base
ARG STRUCTURIZR_VERSION
ENV STRUCTURIZR_VERSION=${STRUCTURIZR_VERSION}

RUN apk update \
    && apk upgrade \
    && apk add unzip curl bash openjdk11-jre

WORKDIR /download

RUN curl -L -o structurizr-cli.zip https://github.com/structurizr/cli/releases/download/v$STRUCTURIZR_VERSION/structurizr-cli-$STRUCTURIZR_VERSION.zip \
    && mkdir -p /cli/structurizr \
    && unzip structurizr-cli.zip -d /cli/structurizr

WORKDIR /workdir
RUN rm -R /download
ENV PATH=/cli/structurizr:$PATH
