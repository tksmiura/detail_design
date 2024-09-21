FROM ubuntu:22.04

MAINTAINER Takeshi Miura <tks.miu@gmail.com>


ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y git build-essential gcc gdb doxygen pandoc
RUN apt-get install -y curl wget
RUN apt-get install -y nodejs npm
RUN npm install -g -y n
RUN apt-get purge -y nodejs npm
RUN apt-get -y autoremove
RUN n stable
RUN apt-get -y install npm
RUN hash -r
RUN npm install -y -g npm@latest
RUN npm install -y -g puppeteer@latest
RUN npm install -y -g corepack@latest
RUN apt-get install -y chromium-browser
RUN npm install -y -g @mermaid-js/mermaid-cli@9.1.7

RUN mkdir /build
WORKDIR /build
