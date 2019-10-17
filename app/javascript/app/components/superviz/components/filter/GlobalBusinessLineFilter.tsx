import React from "react";
import { GlobalFilterController } from "./GlobalFilterController";
import { DropButton, Box, Button } from "grommet";
import { FactTableFilterContext } from "./GetWarehouseFilters";

export const GlobalBusinessLineFilter = (props: { filtersContext: FactTableFilterContext }) => {
  const controller = React.useContext(GlobalFilterController.Context);

  return (
    <DropButton
      label="Business Line"
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
        </Box>
      }
    />
  );
};
