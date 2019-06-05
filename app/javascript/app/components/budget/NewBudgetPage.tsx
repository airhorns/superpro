import React from "react";
import { Page } from "../common";
import { Formant } from "flurishlib/formant";
import { BudgetForm, BudgetFormValues } from "./BudgetForm";

export default class NewBudgetPage extends Page {
  render() {
    return (
      <Page.Layout title="Budget">
        <Formant<BudgetFormValues> initialValues={{ budget: { sections: [] } }} onSubmit={console.log}>
          {form => <BudgetForm form={form} />}
        </Formant>
      </Page.Layout>
    );
  }
}
