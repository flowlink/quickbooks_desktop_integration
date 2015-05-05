FROM rlister/ruby:2.1.6
MAINTAINER Ric Lister, ric@spreecommerce.com

RUN apt-get update && apt-get install -y \
    build-essential zlib1g-dev libreadline6-dev libyaml-dev libssl-dev \
    locales \
    git

## set the locale so gems built for utf8
RUN dpkg-reconfigure locales && \
    locale-gen C.UTF-8 && \
    /usr/sbin/update-locale LANG=C.UTF-8
ENV LC_ALL C.UTF-8

RUN gem install bundler --no-rdoc --no-ri

## help docker cache bundle
WORKDIR /tmp
ADD ./Gemfile /tmp/
ADD ./Gemfile.lock /tmp/
RUN bundle install
RUN rm -f /tmp/Gemfile /tmp/Gemfile.lock

WORKDIR /app
ADD ./ /app

EXPOSE 5000

ENTRYPOINT [ "bundle", "exec" ]
CMD [ "foreman", "start" ]
