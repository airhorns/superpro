import { ISO8601DateString } from "superlib";
import { SuperFormController } from "superlib/superform";
import { BudgetFormValues, BudgetFormLineSeriesValue } from "./BudgetForm";

export const setLineAsFixedValueType = (form: SuperFormController<BudgetFormValues>, linePath: string, occursAt: ISO8601DateString) => {
  form.batch(() => {
    if (form.getValue(linePath + ".type") != "fixed") {
      form.setValue(linePath, { type: "fixed", recurrenceRules: null, amountScenarios: {} });
    }

    form.setValue(linePath + ".type", "fixed");
    form.setValue(linePath + ".occursAt", occursAt);
  });
};

export const setLineAsSeriesValueType = (form: SuperFormController<BudgetFormValues>, linePath: string) => {
  form.batch(() => {
    if (form.getValue(linePath + ".type") != "series") {
      const value: BudgetFormLineSeriesValue = {
        type: "series",
        scenariosEnabled: false,
        cells: {}
      };
      form.setValue(linePath, value);
    }
  });
};

export const toggleLineSeriesValueScenariosEnabled = (form: SuperForm<BudgetFormValues>, linePath: string) => {
  const scenariosEnabledKey = `${linePath}.value.scenariosEnabled`;
  const enabled = form.getValue(scenariosEnabledKey);
  if (enabled) {
    form.setValue(scenariosEnabledKey, false);
    const cells: BudgetFormLineSeriesValue["cells"] = form.getValue(`${linePath}.value.cells`);
    Object.entries(cells).forEach(([cellKey, value]) => {
      for (let scenario in value.amountScenarios) {
        if (scenario != "default") {
          form.deletePath(`${linePath}.value.cells.${cellKey}.${scenario}`);
        }
      }
    });
  } else {
    form.setValue(scenariosEnabledKey, true);
  }
};
