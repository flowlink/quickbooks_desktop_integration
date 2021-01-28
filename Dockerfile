FROM nurelmdevelopment/quickbooks-desktop-integration-base:0.3
MAINTAINER NuRelm <development@nurelm.com>

## help docker cache bundle
WORKDIR /app
COPY ./Gemfile .
COPY ./Gemfile.lock .

RUN NOKOGIRI_USE_SYSTEM_LIBRARIES=true bundle install --jobs=4

RUN apt-get remove -yq build-essential pkg-config && \
    apt-get autoremove -yq && \
    apt-get clean

COPY ./ /app

ENTRYPOINT [ "bundle", "exec" ]
CMD [ "foreman", "start" ]
