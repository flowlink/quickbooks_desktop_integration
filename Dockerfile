FROM rlister/ruby:2.4.0
MAINTAINER NuRelm <development@nurelm.com>

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -yq \
    build-essential zlib1g-dev libreadline6-dev libyaml-dev libssl-dev \
    locales \
    git

## set the locale so gems built for utf8
RUN dpkg-reconfigure locales && \
    locale-gen C.UTF-8 && \
    /usr/sbin/update-locale LANG=C.UTF-8
ENV LC_ALL C.UTF-8

## help docker cache bundle
WORKDIR /tmp
COPY ./Gemfile /tmp/
COPY ./Gemfile.lock /tmp/

RUN bundle install
RUN rm -f /tmp/Gemfile /tmp/Gemfile.lock

WORKDIR /app
COPY ./ /app

EXPOSE 5000

ENTRYPOINT [ "bundle", "exec" ]
CMD [ "foreman", "start" ]
