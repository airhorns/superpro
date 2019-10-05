Cypress.Commands.add("cleanServer", () =>
  cy.request({
    method: "POST",
    url: "/test_support/clean",
    log: true,
    failOnStatusCode: true
  })
);

Cypress.Commands.add("login", (email = "cypress@superpro.io") =>
  cy.request({
    method: "POST",
    url: "/test_support/force_login",
    body: { email },
    log: true,
    failOnStatusCode: true
  })
);

Cypress.Commands.add("emptyAccount", () =>
  cy
    .request({
      method: "POST",
      url: "/test_support/empty_account",
      log: true,
      failOnStatusCode: true
    })
    .its("body")
    .as("account")
);

Cypress.Commands.add("getLastEmail", () =>
  cy
    .wait(700)
    .request({
      method: "GET",
      url: "/test_support/last_delivered_email",
      log: true,
      failOnStatusCode: true
    })
    .its("body")
    .as("last_email")
);

Cypress.Commands.add("setAccountFlipperFlag", (flag, value) =>
  cy.get("@account").then(account =>
    cy.request({
      method: "POST",
      url: "/test_support/set_account_flipper_flag",
      body: { flag, value, account_id: account.id },
      log: true,
      failOnStatusCode: true
    })
  )
);
