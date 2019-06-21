import { ISO8601DateString } from "flurishlib";
import { SuperForm } from "flurishlib/superform";
import { BudgetFormValues, BudgetFormLineSeriesValue } from "./BudgetForm";

export const setLineAsFixedValueType = (form: SuperForm<BudgetFormValues>, linePath: string, occursAt: ISO8601DateString) => {
  form.batch(() => {
    if (form.getValue(linePath + ".type") != "fixed") {
      form.setValue(linePath, { type: "fixed", recurrenceRules: null, amountScenarios: {} });
    }

    form.setValue(linePath + ".type", "fixed");
    form.setValue(linePath + ".occursAt", occursAt);
  });
};

export const setLineAsSeriesValueType = (form: SuperForm<BudgetFormValues>, linePath: string) => {
  form.batch(() => {
    if (form.getValue(linePath + ".type") != "series") {
      const value: BudgetFormLineSeriesValue = {
        type: "series",
        cells: {}
      };
      form.setValue(linePath, value);
    }
  });
};
