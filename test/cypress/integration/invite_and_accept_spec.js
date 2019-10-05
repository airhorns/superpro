import { getEmailBody } from "../support/helpers";

describe("Inviting and accepting", function() {
  beforeEach(() => {
    cy.emptyAccount();
    cy.login();
  });

  it("can send an invite to a new user, who can then accept it, and get taken home", function() {
    cy.visit("/invite");
    cy.contains("Invite Users");

    cy.get("input[name='user.email']").type("an-example@email.com");
    cy.get("[data-testid=invite-submit]").click();
    cy.contains("User invited!");

    cy.getLastEmail().then(email => {
      const link = getEmailBody(email).match(/href=".*?app\.supo\.dev([^"]+)/)[1];
      cy.expect(link).to.not.be.undefined;
      cy.clearCookies();
      cy.visit(link);

      cy.get("input[name='user.full_name']").type("Example User");
      cy.get("input[name='user.password']").type("secret123");
      cy.get("input[name='user.password_confirmation']").type("secret123");
      cy.get("[data-testid=sign-up-submit]").click();

      cy.contains("Home");
    });
  });

  it("can send an invite to a new user, who can then accept it, and get taken to connection setup if they don't have product access yet", function() {
    cy.visit("/invite");
    cy.contains("Invite Users");

    cy.get("input[name='user.email']").type("an-example@email.com");
    cy.get("[data-testid=invite-submit]").click();
    cy.contains("User invited!");

    cy.getLastEmail().then(email => {
      cy.setAccountFlipperFlag("gate.productAccess", false);
      const link = getEmailBody(email).match(/href=".*?app\.supo\.dev([^"]+)/)[1];
      cy.expect(link).to.not.be.undefined;
      cy.clearCookies();
      cy.visit(link);

      cy.get("input[name='user.full_name']").type("Example User");
      cy.get("input[name='user.password']").type("secret123");
      cy.get("input[name='user.password_confirmation']").type("secret123");
      cy.get("[data-testid=sign-up-submit]").click();

      cy.contains("Welcome to Superpro");
      cy.get("button").click();
    });
  });
});
