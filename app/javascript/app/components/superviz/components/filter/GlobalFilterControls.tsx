import React from "react";
import { Row } from "superlib";
import { keyBy } from "lodash";
import { GlobalDateFilter } from "./GlobalDateFilter";
import { FactTableFilterContext } from "./GetWarehouseFilters";
import { GlobalBusinessLineFilter } from "./GlobalBusinessLineFilter";

export const GlobalFilterControls = (props: { enabledFilters: string[]; filtersContext: FactTableFilterContext }) => {
  const filters = keyBy(props.enabledFilters);
  return (
    <Row gap="small">
      {filters["date"] && <GlobalDateFilter />}
      {filters["business_line_id"] && <GlobalBusinessLineFilter filtersContext={props.filtersContext} />}
    </Row>
  );
};
