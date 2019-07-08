# README

### Dev Cheatsheet

- `yarn generate-graphql`: Generate TypeScript queries and components for all client side GraphQL queries in the codebase
- `bin/lintfix`: Automatically format all Ruby and TypeScript code to match linter specifications
- `bin/lint`: Check if all Ruby and TypeScript code matches linter rules
- `bin/rails db:truncate db:seed`: Reset the database to a fresh, development friendly state. Destructive but recreates a bunch of useful test data
- `bin/rails test`: Run all Ruby tests
- `bin/yarn test`: Run all TypeScript tests
- `bin/yarn open-cypress`: Open interactive end-to-end test runner, [Cypress](https://www.cypress.io/)

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
