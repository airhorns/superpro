import React from "react";
import { VizBlock, Document } from "../schema";
import { GetWarehouseData, VizQueryContext } from "./GetWarehouseData";
import { RechartsPlotRenderer } from "./RechartsPlotRenderer";
import { CohortTableRenderer } from "./CohortTableRenderer";
import { Box, Heading } from "grommet";

export const VizBlockRenderer = (props: { doc: Document; block: VizBlock }) => (
  <GetWarehouseData query={props.block.query}>
    <VizQueryContext.Consumer>
      {result => {
        let viz: React.ReactNode;
        if (props.block.viz.systems[0].vizType == "cohorts") {
          viz = <CohortTableRenderer doc={props.doc} block={props.block} result={result} />;
        } else {
          viz = <RechartsPlotRenderer doc={props.doc} block={props.block} result={result} />;
        }

        return (
          <Box fill>
            {props.block.title && <Heading level="3">{props.block.title}</Heading>}
            {viz}
          </Box>
        );
      }}
    </VizQueryContext.Consumer>
  </GetWarehouseData>
);
