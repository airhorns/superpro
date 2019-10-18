import React from "react";
import ReactSelect from "react-select";
import { Row, SuperproReactSelectTheme, isArrayOptionType } from "superlib";
import { ValueType } from "react-select/lib/types";
import { VizBlock, TableBlock, VizType } from "../../schema";
import { ReportBuilderContext } from "./ReportBuilder";
import { find } from "lodash";

interface VizTypeOptionType {
  value: VizType | "table";
  label: React.ReactNode | string;
}

const vizTypeOptions: VizTypeOptionType[] = [
  { value: "line", label: "Line" },
  { value: "bar", label: "Bar" },
  { value: "table", label: "Table" }
];

export const VizTypeSelector = (props: { block: VizBlock | TableBlock; blockIndex: number }) => {
  const controller = React.useContext(ReportBuilderContext);

  let selectedOption: VizTypeOptionType | undefined = undefined;
  if (props.block.type == "table_block") {
    selectedOption = find(vizTypeOptions, { value: "table" });
  } else {
    const firstSystemType = props.block.viz.systems[0] && props.block.viz.systems[0].vizType;
    selectedOption = find(vizTypeOptions, { value: firstSystemType });
  }

  return (
    <Row gap="small">
      <ReactSelect
        theme={SuperproReactSelectTheme}
        value={selectedOption}
        styles={{ container: provided => ({ ...provided, minWidth: "300px" }) }}
        options={vizTypeOptions}
        onChange={(option: ValueType<VizTypeOptionType>) => {
          if (option) {
            if (isArrayOptionType(option)) {
              throw "Unexpected array option";
            }
            controller.setBlockVizType(props.blockIndex, option.value);
          }
        }}
      />
    </Row>
  );
};
