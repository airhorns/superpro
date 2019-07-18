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

### Structure

Superpro is a Rails app with a React frontend that communicates over GraphQL.

Useful directories:

- `app/models`: Contains data models backed by database tables using Rails' ActiveRecord models.
- `app/services`: Contains business logic modeled as discrete operations
- `app/graphql`: Contains GraphQL types, queries, and mutations allowing the client side to fetch data or invoke services
- `app/javascript/app`: Contains the client side application, the front of the frontend
- `app/javascript/superlib`: Contains supporting libraries for the client side application, the back of the frontend

We do our best to keep these principles in mind, within reason:

- What can be done on the server should be done on the server. Frontends should be as dumb as possible in order to make writing more fo them easier.
- Code should be written to be read, which usually means writing it is a little bit slower. We use types, descriptive variable names, and a little more boilerplate than other Rails apps might. This is to make it really easy to join the project, not break stuff, and change stuff quickly.
