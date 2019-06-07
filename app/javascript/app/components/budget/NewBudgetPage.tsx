import React from "react";
import shortid from "shortid";
import { Page } from "../common";
import { BudgetForm, BudgetFormValues } from "./BudgetForm";
import { SuperForm } from "flurishlib/superform";

export default class NewBudgetPage extends Page {
  render() {
    return (
      <Page.Layout title="Budget">
        <SuperForm<BudgetFormValues> initialValues={{ budget: { id: shortid(), lines: [], sections: [] } }}>
          {form => <BudgetForm form={form} />}
        </SuperForm>
      </Page.Layout>
    );
  }
}
