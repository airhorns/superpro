import React from "react";
import { VizBlock, ReportDocument } from "../../schema";
import { GetWarehouseData } from "../GetWarehouseData";
import { CohortTableRenderer } from "./CohortTableRenderer";
import { Box, Heading } from "grommet";
import { EchartsPlotRenderer } from "./EchartsPlotRenderer";

export const VizBlockRenderer = (props: { doc: ReportDocument; block: VizBlock }) => (
  <GetWarehouseData query={props.block.query}>
    {result => {
      let viz: React.ReactNode;
      if (props.block.viz.systems[0].vizType == "cohorts") {
        viz = <CohortTableRenderer doc={props.doc} block={props.block} result={result} />;
      } else {
        viz = <EchartsPlotRenderer doc={props.doc} block={props.block} result={result} />;
      }

      return (
        <Box flex={{ grow: 1, shrink: 0 }} style={{ minHeight: "400px" }}>
          {props.block.title && <Heading level="3">{props.block.title}</Heading>}
          {viz}
        </Box>
      );
    }}
  </GetWarehouseData>
);
