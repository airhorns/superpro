import React from "react";
import { Row } from "superlib";
import { keyBy } from "lodash";
import { GlobalDateFilter } from "./GlobalDateFilter";

export const GlobalFilterControls = (props: { filters: string[] }) => {
  const filters = keyBy(props.filters);
  return (
    <Row gap="small">
      {filters["date"] && <GlobalDateFilter />}
      {/* {filters["business_line_id"] && <GlobalBusinessLineFilter />} */}
    </Row>
  );
};
