# ------------------------------------------------------------------------------
# Base
# ------------------------------------------------------------------------------
FROM ruby:2.6.6 as base
MAINTAINER dxw <rails@dxw.com>

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash
RUN curl https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

RUN apt-get update && apt-get install -qq -y \
  build-essential \
  libpq-dev \
  --fix-missing --no-install-recommends

ENV APP_HOME /srv/app
ENV DEPS_HOME /deps

ARG RAILS_ENV
ENV RAILS_ENV ${RAILS_ENV:-production}
ENV NODE_ENV ${RAILS_ENV:-production}

# ------------------------------------------------------------------------------
# Dependencies
# ------------------------------------------------------------------------------
FROM base AS dependencies

RUN mkdir -p ${DEPS_HOME}
WORKDIR $DEPS_HOME

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - \
  && apt-get install -y nodejs

# Install Javascript dependencies
COPY package-lock.json $DEPS_HOME/package-lock.json
COPY package.json $DEPS_HOME/package.json
RUN npm install

# Install Ruby dependencies
COPY Gemfile $DEPS_HOME/Gemfile
COPY Gemfile.lock $DEPS_HOME/Gemfile.lock
RUN gem update --system
RUN gem install bundler -v 2.2.16

ENV BUNDLE_GEM_GROUPS=$RAILS_ENV
RUN bundle config set frozen "true"
RUN bundle config set no-cache "true"
RUN bundle config set with $BUNDLE_GEM_GROUPS
RUN bundle install --no-binstubs --retry=10 --jobs=4

# ------------------------------------------------------------------------------
# Web
# ------------------------------------------------------------------------------
FROM dependencies AS web

RUN mkdir -p ${APP_HOME}
WORKDIR ${APP_HOME}

# Copy app code (sorted by vague frequency of change for caching)
RUN mkdir -p ${APP_HOME}/log
RUN mkdir -p ${APP_HOME}/tmp

COPY config.ru ${APP_HOME}/config.ru
COPY Rakefile ${APP_HOME}/Rakefile

COPY Gemfile $APP_HOME/Gemfile
COPY Gemfile.lock $APP_HOME/Gemfile.lock

COPY public ${APP_HOME}/public
COPY vendor ${APP_HOME}/vendor
COPY bin ${APP_HOME}/bin
COPY lib ${APP_HOME}/lib
COPY config ${APP_HOME}/config
COPY db ${APP_HOME}/db
COPY script ${APP_HOME}/script
COPY app ${APP_HOME}/app
# End

# Create tmp/pids
RUN mkdir -p tmp/pids

# This must be ordered before rake assets:precompile
RUN cp -R $DEPS_HOME/node_modules $APP_HOME/node_modules
RUN cp -R $DEPS_HOME/node_modules/govuk-frontend/govuk/assets $APP_HOME/app/assets

RUN RAILS_ENV=production \
    SECRET_KEY_BASE="key" \
    APPLICATION_URL= \
    CONTENTFUL_URL= \
    CONTENTFUL_SPACE= \
    CONTENTFUL_ENVIRONMENT= \
    CONTENTFUL_ACCESS_TOKEN= \
    CONTENTFUL_DEFAULT_CATEGORY_ENTRY_ID= \
    CONTENTFUL_PREVIEW_APP= \
    CONTENTFUL_ENTRY_CACHING= \
    SUPPORT_EMAIL= \
    REDIS_URL= \
    bundle exec rake assets:precompile

COPY ./docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 3000

CMD ["bundle", "exec", "rails", "server"]

# ------------------------------------------------------------------------------
# Test
# ------------------------------------------------------------------------------
FROM web as test

RUN apt-get install -qq -y shellcheck wait-for-it

COPY package.json ${APP_HOME}/package.json
COPY package-lock.json ${APP_HOME}/package-lock.json

COPY .rspec ${APP_HOME}/.rspec
COPY spec ${APP_HOME}/spec
