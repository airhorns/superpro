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

    brew install postgres nss mkcert

Configure [`mkcert`](https://github.com/FiloSottile/mkcert) for your local machine and generate a development SSL certificate:

    mkcert -install
    mkcert -cert-file config/docker-compose/server.crt -key-file config/docker-compose/server.key supo.dev "*.supo.dev"

Install gems

    bundle

Install JS dependencies

    yarn

Install [Docker for Mac](https://hub.docker.com/editions/community/docker-ce-desktop-mac) and `gcloud`:

    brew install google-cloud-sdk

Configure it to connect to our Google Cloud docker container registry, and then boot containers:

    gcloud auth login
    gcloud auth configure-docker
    docker-compose up

Setup DB:

    bin/rails db:setup

And you're off to the races!

### Running A Dev Server

You need to be running 3 processes to run a local instance of Superpro:

- `docker-compose up`: Runs background daemons to power Superpro, like the database, nginx, Redis, and potentially more in the future.
- `bin/rails server`: Runs the Ruby server process to render pages requested by the browser
- `bin/webpack-dev-server`: Runs a Node server process to compile, serve, and cache assets (almost all JavaScript) to the browser with much faster re-compile speeds. We keep this one separate because it is very sensitive to the performance hit of running inside docker, and affects developer iteration speed a lot.

Run these three (most do it in separate terminal windows) processes, and then visit https://app.supo.dev, which will point to your local Superpro instance.

#### Auxiliary Development Services

You can also run a jobs server to execute background jobs enqueued locally in the foreground for testing and debugging. Use:

```
bundle exec que -q default -q mailers
```

to execute Que, our jobs system.

### Customer Data Warehouse

Changes to the structure of the actual data that Superpro serves are made in the `customer-warehouse` repository, which contains all our data models and the infrastructure to keep them up to date. This Rails app is coupled to those models and depends on them existing in order to work. The structure of the warehouse is dumped using Rails' support for SQL schema on disk, which is good, so a normal `bin/rails db:prepare` sets up the tables from the warehouse.

#### Running tests during development

To run the Rails land tests, run:

```
bin/rails test
```

To run the JavaScript land tests, run:

```
yarn run test
```

If changes are made to the structure of the development database outside of Rails' migrations (which is the case for `customer-warehouse` side changes), Rails doesn't know that things have changed. This means the test database will fall out of sync with the development database. To recreate the test database with the most up to date version of the development database's structure, run:

```
bin/rails db:structure:dump dbt:test:prepare
```

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

### Contributing

Developers are encouraged but not required to use VSCode and an associated plugin stack to hack on Superpro. We've invested in making this environment really productive and find that our technology choices work best in VSCode.

The recommended VSCode plugins are:

- Prettier: https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode
- ESLint: ahttps://marketplace.visualstudio.com/items?itemName=dbaeumer.vscode-eslint
- Apollo GraphQL: https://marketplace.visualstudio.com/items?itemName=apollographql.vscode-apollo
- Jest: https://marketplace.visualstudio.com/items?itemName=Orta.vscode-jest
- Path Intellisense: https://marketplace.visualstudio.com/items?itemName=christian-kohler.path-intellisense
- Rails: https://marketplace.visualstudio.com/items?itemName=bung87.rails
- Ruby: https://marketplace.visualstudio.com/items?itemName=rebornix.Ruby
- Ruby Solargraph: https://marketplace.visualstudio.com/items?itemName=castwide.solargraph
- Ruby Symbols: https://marketplace.visualstudio.com/items?itemName=miguel-savignano.ruby-symbols
- rufo (Ruby formatter): https://marketplace.visualstudio.com/items?itemName=mbessey.vscode-rufo

We also highly recommend enabling some quality of life settings for VSCode. You can find them all in the repository under `.vscode/settings.json.example`, and you can bootstrap your editor setup by running:

`$ cp .vscode/settings.json.example .vscode/settings.json`

We force all Superpro code to be linted because it avoids uncessary bugs, and shortens the development cycle by giving in-editor feedback about all sorts of stuff. With the appropriate editor settings, we feel that linters actually make development _faster_, especially because both the Ruby and TypeScript linters support automatic re-formatting of the code. So, you should very rarely have to manually format code. To avoid wasting time doing that, turning on the VSCode `editor.formatOnSave` setting is real important. There's also two scripts to make linting and lint-fixing easier:

- `bin/lint` runs both Ruby and TypeScript linters to report any errors
- `bin/lintfix` runs the autocorrecting version of the Ruby and TypeScript linters to fix any issues the linters can automatically fix for you.

We also try to remain pragmatic about linting. If there's a rule that is on that you think is dumb or is wasting your time, open a PR to disable it and the team should discuss! Linting is about developer productivity, not a misplaced sense of order or cleanliness.

### Meta Contributing

Superpro should be structured to be easy to contribute to! If there's something that isn't obvious, or is hard to get set up, we're not doing our jobs as a development team. Those hard things need to be systematically eliminated so that we maintain productivity. Investment in making contributing easy can be a lot of different things:

- English explaining stuff in the README.md, folder specific READMEs, or big comment blocks. Commenting non-obvious code is a great idea.
- Setup guides to explain how to get a local development environment going for a particular feature
- Setup scripts to provision a local devleopment environment or remote credentials or whatever
- Shared remote credentials so that development "just works"
- Abstractions in the code that make development faster or easier, like React components or mini Ruby gems.

#### Running Integration Tests

To run the integration tests locally, you need to reboot your development environment into the `integration_test` environment. This means setting the `RAILS_ENV` to `integration_test` for all the processes that need to be running for the tests to pass. So:

Stop your development server, then start it again with:

    RAILS_ENV=integration_test SECRET_KEY_BASE=foobarbaz bin/rails server

Stop your webpack-dev-server and then start it again with:

    env RAILS_ENV=integration_test bin/webpack-dev-server

Once you have a running server in the integration test environment, you can run Cypress, the integration testing server.

    yarn run open-cypress

And test away!
