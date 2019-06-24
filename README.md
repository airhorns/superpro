# README

### Dev Setup

Install homebrew deps for your host:

    brew install postgres mkcert

Configure [`mkcert`](https://github.com/FiloSottile/mkcert) for your local machine and generate a development SSL certificate:

    mkcert -install
    mkcert -cert-file config/docker-compose/server.crt -key-file config/docker-compose/server.key ggt.dev "*.ggt.dev"

Install gems

    bundle

Install JS dependencies

    yarn

Install [Docker for Mac](https://hub.docker.com/editions/community/docker-ce-desktop-mac) and boot containers:

    docker-compose up

Setup DB:

    bin/rails db:setup

And you're off to the races!

### Handy Dev Scripts

- `bin/rake db:truncate db:seed`: Reset the database to a fresh, development friendly state. Destructive but recreates a bunch of useful test data
