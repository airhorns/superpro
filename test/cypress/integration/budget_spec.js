describe("Budget Editing", function() {
  beforeEach(() => {
    cy.emptyAccount();
    cy.login();
  });

  it("can view the default budget", function() {
    cy.visit("/budget");
    cy.get('[data-test-id="add-section-Services"]').click();
    cy.get('input[name="budget.lines.0.description"]').type("Janitorial");
    cy.get('input[name="budget.lines.0.amountScenarios.default"]').click().type("{backspace}{backspace}{backspace}100");
    cy.get('body').click()
  });
});
