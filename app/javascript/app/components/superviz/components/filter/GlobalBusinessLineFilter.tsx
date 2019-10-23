import React from "react";
import { GlobalFilterController } from "./GlobalFilterController";
import { DropButton, Box, Button } from "grommet";
import { FactTableFilterContext } from "./GetWarehouseFilters";
import { assert } from "superlib";
import { find } from "lodash";

export const GlobalBusinessLineFilter = (props: { filtersContext: FactTableFilterContext }) => {
  const controller = React.useContext(GlobalFilterController.Context);
  let label: string;

  if (controller.state.filters["business_line_id"]) {
    const selectedId = assert(assert(controller.state.filters["business_line_id"].values)[0]);
    const selectedBusinessLine = assert(find(props.filtersContext.businessLines, ["id", selectedId]));
    label = selectedBusinessLine.name;
  } else {
    label = "All Business Lines";
  }

  return (
    <DropButton
      label={label}
      dropAlign={{ top: "bottom", right: "right" }}
      dropContent={
        <Box pad="medium" background="light-1" gap="small">
          {Object.values(props.filtersContext.businessLines).map(businessLine => (
            <Button
              key={businessLine.id}
              plain
              label={businessLine.name}
              onClick={() => {
                controller.setFilter("business_line_id", "equals", [businessLine.id]);
              }}
            />
          ))}
          <Button
            plain
            label="All Business Lines"
            onClick={() => {
              controller.removeFilter("business_line_id");
            }}
          />
        </Box>
      }
    />
  );
};
