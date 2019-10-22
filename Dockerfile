# Alias the node container matching the same linux distro as `nodejs`
FROM node:11.15.0-stretch as nodejs

# Get all the ruby dependencies installed as they are needed for both building assets and the final output container
FROM ruby:2.6.2-stretch as ruby_environment
RUN mkdir /app
WORKDIR /app

COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock
RUN bundle install -j 20 --without development test deploy --deployment

COPY --from=nodejs /usr/local/bin/node /usr/local/bin/
COPY --from=nodejs /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=nodejs /opt/ /opt/
RUN ln -sf /usr/local/bin/node /usr/local/bin/nodejs \
  && ln -sf ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
  && ln -sf ../lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx \
  && ln -sf /opt/yarn*/bin/yarn /usr/local/bin/yarn \
  && ln -sf /opt/yarn*/bin/yarnpkg /usr/local/bin/yarnpkg


# Build a fat container that has both node and ruby and both sets of dependencies available so it can run webpacker
# This stage's layers don't make it into the final image.
FROM ruby_environment as assets

COPY package.json /app/package.json
COPY yarn.lock /app/yarn.lock
RUN yarn

COPY . /app/

# Run webpacker to build the assets that can then be copied into the final image
RUN NODE_ENV=production RAILS_ENV=production SECRET_KEY_BASE=valueneededtobootapp APP_JWT_SECRET=valueneededtobootapp REDIS_URL=redis://valueneededtobootapp:1234 bin/rake --trace assets:precompile

# Start a fresh container and copy only the produced webpacker assets in, leaving the node binaries and yarn packages behind
FROM ruby_environment
ARG RELEASE=unknown

COPY . /app/
COPY --from=assets /app/public /app/public
RUN echo $RELEASE > /app/RELEASE