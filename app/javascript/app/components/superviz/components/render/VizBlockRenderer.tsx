import React from "react";
import { VizBlock, ReportDocument } from "../../schema";
import { GetWarehouseData } from "../GetWarehouseData";
import { CohortTableRenderer } from "./CohortTableRenderer";
import { Heading, Box } from "grommet";
import { EchartsPlotRenderer, heightForBlock } from "./EchartsPlotRenderer";
import { pivotForViz } from "../../pivot";
import styled from "styled-components";

export const StyledVizBoxContainer = styled(Box)`
  @media print {
    display: block;
    page-break-inside: avoid;
  }
`;

export const VizBlockRenderer = (props: { doc: ReportDocument; block: VizBlock }) => (
  <StyledVizBoxContainer style={{ minHeight: heightForBlock(props.block) }} flex="grow">
    {props.block.title && <Heading level="3">{props.block.title}</Heading>}
    <GetWarehouseData query={props.block.query} pivot={pivotForViz(props.block)}>
      {result => {
        if (props.block.viz.systems[0].vizType == "cohorts") {
          return <CohortTableRenderer doc={props.doc} block={props.block} result={result} />;
        } else {
          return <EchartsPlotRenderer doc={props.doc} block={props.block} result={result} />;
        }
      }}
    </GetWarehouseData>
  </StyledVizBoxContainer>
);
