Cypress.Commands.add("cleanServer", () => cy.request({
  method: 'POST',
  url: "/test_support/clean",
  log: true,
  failOnStatusCode: true
}))

Cypress.Commands.add("login", (email) => cy.request({
  method: 'POST',
  url: "/test_support/force_login",
  body: {email},
  log: true,
  failOnStatusCode: true
}))

Cypress.Commands.add("emptyApp", () => cy.request({
  method: 'POST',
  url: "/test_support/empty_app",
  log: true,
  failOnStatusCode: true
}).its('body').as('app'))

Cypress.Commands.add("kitchenSinkApp", () => cy.request({
  method: 'POST',
  url: "/test_support/kitchen_sink_app",
  log: true,
  failOnStatusCode: true
}).its('body').as('app'))
