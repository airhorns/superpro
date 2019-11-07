import ReactSelect, { ValueType } from "react-select";
import React from "react";
import { Row, SuperproReactSelectTheme, isArrayOptionType } from "superlib";
import { VizBlock, TableBlock } from "../../schema";
import { ReportBuilderContext } from "./ReportBuilder";
import { Dimension } from "../../WarehouseQuery";
import { find, isUndefined } from "lodash";
import { TrashButton } from "app/components/common";

interface DimensionOptionType {
  value: string;
  labelInSelect: string | React.ReactNode;
  labelWhenSelected: string | React.ReactNode;
  fieldName: string;
  modelName: string;
}

interface OperatorOptionType {
  value: Dimension["operator"] | null;
  label: string | React.ReactNode;
}

const operatorOptions: OperatorOptionType[] = [
  { label: "As is", value: null },
  { label: "Round to Year", value: "date_trunc_year" },
  { label: "Round to Month", value: "date_trunc_month" },
  { label: "Round to Week", value: "date_trunc_week" },
  { label: "Round to Day", value: "date_trunc_day" },
  { label: "Round to Hour", value: "date_part_hour" },
  { label: "Day of Month ", value: "date_part_day_of_month" },
  { label: "Day of Week ", value: "date_part_day_of_week" },
  { label: "Relative Week ", value: "date_part_week" },
  { label: "Relative Month ", value: "date_part_month" },
  { label: "Relative Year ", value: "date_part_year" },
  { label: "Average ", value: "average" },
  { label: "Sum ", value: "sum" },
  { label: "Maximum", value: "max" },
  { label: "Minimum", value: "min" },
  { label: "Count ", value: "count" },
  { label: "Count of Unique", value: "count_distinct" },
  { label: "80th Percentile", value: "p80" },
  { label: "90th Percentile", value: "p90" },
  { label: "95th Percentile", value: "p95" }
];

export const DimensionForm = (props: { block: VizBlock | TableBlock; blockIndex: number; dimension: Dimension }) => {
  const controller = React.useContext(ReportBuilderContext);
  const measuredFactTables = controller.factTablesQueriedForBlockIndex(props.blockIndex);

  const dimensionOptionGroups = React.useMemo(
    () =>
      controller.warehouse.factTables
        .filter(table => measuredFactTables.includes(table.name))
        .map(table => ({
          label: table.name,
          model: table.name,
          options: table.dimensionFields.map(field => ({
            modelName: table.name,
            fieldName: field.fieldName,
            value: `${table.name}::${field.fieldName}`,
            labelInSelect: field.fieldLabel,
            labelWhenSelected: `${table.name} ${field.fieldLabel}`
          }))
        })),
    [controller, measuredFactTables]
  );

  const selectedModel = find(dimensionOptionGroups, { model: props.dimension.model });
  let selectedDimension: DimensionOptionType | undefined = undefined;
  if (selectedModel) {
    selectedDimension = find(selectedModel.options, { fieldName: props.dimension.field });
  }

  const selectedOperator: OperatorOptionType | undefined = find(operatorOptions, {
    value: isUndefined(props.dimension.operator) ? null : props.dimension.operator
  });

  return (
    <Row gap="small">
      <ReactSelect
        theme={SuperproReactSelectTheme}
        value={selectedDimension}
        styles={{ container: provided => ({ ...provided, minWidth: "300px" }) }}
        options={dimensionOptionGroups}
        formatOptionLabel={(option, context) => {
          if (context.context == "menu") {
            return option.labelInSelect;
          } else {
            return option.labelWhenSelected;
          }
        }}
        onChange={(option: ValueType<DimensionOptionType>) => {
          if (option) {
            if (isArrayOptionType(option)) {
              throw "Unexpected array option";
            }
            controller.setDimensionField(props.blockIndex, props.dimension.id, option.modelName, option.fieldName);
          }
        }}
      />
      <ReactSelect
        theme={SuperproReactSelectTheme}
        value={selectedOperator}
        styles={{ container: provided => ({ ...provided, minWidth: "200px" }) }}
        options={operatorOptions}
        onChange={(option: ValueType<OperatorOptionType>) => {
          if (option) {
            if (isArrayOptionType(option)) {
              throw "Unexpected array option";
            }
            controller.setDimensionOperator(props.blockIndex, props.dimension.id, option.value);
          }
        }}
      />
      <TrashButton
        onClick={() => {
          controller.removeDimensionField(props.blockIndex, props.dimension.id);
        }}
      />
    </Row>
  );
};
