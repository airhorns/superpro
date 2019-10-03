import ReactSelect from "react-select";
import React from "react";
import { Row, SuperproReactSelectTheme, isArrayOptionType } from "superlib";
import { ValueType } from "react-select/lib/types";
import { VizBlock, TableBlock } from "../../schema";
import { ReportBuilderContext } from "./ReportBuilder";
import { Measure } from "../../WarehouseQuery";
import { find } from "lodash";

interface MeasureOptionType {
  value: string;
  labelInSelect: string | React.ReactNode;
  labelWhenSelected: string | React.ReactNode;
  fieldName: string;
  modelName: string;
}

export const MeasureForm = (props: { block: VizBlock | TableBlock; blockIndex: number; measure: Measure }) => {
  const controller = React.useContext(ReportBuilderContext);
  const measureOptionGroups = React.useMemo(
    () =>
      controller.warehouse.factTables.map(table => ({
        label: table.name,
        model: table.name,
        options: table.measureFields.map(field => ({
          modelName: table.name,
          fieldName: field.fieldName,
          value: `${table.name}::${field.fieldName}`,
          labelInSelect: field.fieldLabel,
          labelWhenSelected: `${table.name} ${field.fieldLabel}`
        }))
      })),
    [controller]
  );

  const selectedModel = find(measureOptionGroups, { model: props.measure.model });
  let selectedOption: MeasureOptionType | undefined = undefined;
  if (selectedModel) {
    selectedOption = find(selectedModel.options, { fieldName: props.measure.field });
  }

  return (
    <Row>
      <ReactSelect
        theme={SuperproReactSelectTheme}
        value={selectedOption}
        styles={{ container: provided => ({ ...provided, minWidth: "300px" }) }}
        options={measureOptionGroups}
        formatOptionLabel={(option, context) => {
          if (context.context == "menu") {
            return option.labelInSelect;
          } else {
            return option.labelWhenSelected;
          }
        }}
        onChange={(option: ValueType<MeasureOptionType>) => {
          if (option) {
            if (isArrayOptionType(option)) {
              throw "Unexpected array option";
            }
            controller.setMeasureField(props.blockIndex, props.measure.id, option.modelName, option.fieldName);
          }
        }}
      />
    </Row>
  );
};
