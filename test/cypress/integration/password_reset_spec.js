describe("Password reset", function() {
  beforeEach(() => {
    cy.emptyAccount();
  });

  it("can reset a password", function() {
    cy.visit("/auth/forgot_password");
    cy.get("#email").type("cypress@superpro.io");

    cy.get("[data-test-id=forgot-password-submit]").click();
    cy.contains("An email has been sent");

    cy.getLastEmail().then(email => {
      const link = email.body.raw_source.match(/href=".*?app\.supo\.dev([^"]*)/)[1];
      cy.visit(link);

      cy.get("#password").type("a-new-password");
      cy.get("[data-test-id=reset-password-submit]").click();
      cy.contains("successfully reset");
      cy.get("a")
        .contains("to enter Superpro")
        .click();

      cy.contains("Launchpad");
    });
  });
});
