Cypress.Commands.add("cleanServer", () => cy.request({
  method: 'POST',
  url: "/test_support/clean",
  log: true,
  failOnStatusCode: true
}))

Cypress.Commands.add("login", (email = "cypress@superpro.io") => cy.request({
  method: 'POST',
  url: "/test_support/force_login",
  body: {email},
  log: true,
  failOnStatusCode: true
}))

Cypress.Commands.add("emptyAccount", () => cy.request({
  method: 'POST',
  url: "/test_support/empty_account",
  log: true,
  failOnStatusCode: true
}).its('body').as('account'))
