import React from "react";
import { Box, Text, Heading, Button } from "grommet";
import { Row } from "superlib";
import { VizBlock, TableBlock } from "../../schema";
import { TableBlockRenderer } from "../render/TableBlockRenderer";
import { VizBlockRenderer } from "../render/VizBlockRenderer";
import { ReportBuilderContext } from "./ReportBuilder";
import { Add } from "app/components/common/SuperproIcons";
import { MeasureForm } from "./MeasureForm";
import { DimensionForm } from "./DimensionForm";
import { VizTypeSelector } from "./VizTypeSelector";

export const AddMeasureButton = (props: { block: VizBlock | TableBlock; blockIndex: number }) => {
  const controller = React.useContext(ReportBuilderContext);
  const onClick = React.useCallback(() => {
    controller.addMeasure(props.blockIndex, "Sales::OrderFacts", "count");
  }, [controller, props.blockIndex]);

  return <Button icon={<Add />} onClick={onClick} />;
};

export const AddDimensionButton = (props: { block: VizBlock | TableBlock; blockIndex: number }) => {
  const controller = React.useContext(ReportBuilderContext);
  const onClick = React.useCallback(() => {
    controller.addDimension(props.blockIndex, "Sales::OrderFacts", "created_at", "date_trunc_day");
  }, [controller, props.blockIndex]);

  return <Button icon={<Add />} onClick={onClick} />;
};

export const QueryBlockEditor = (props: { block: VizBlock | TableBlock; index: number }) => {
  const controller = React.useContext(ReportBuilderContext);
  let output: React.ReactNode;

  if (props.block.query.measures.length == 0 && props.block.query.dimensions.length == 0) {
    output = <Text color="status-disabled">Select some data to populate this block</Text>;
  } else if (props.block.type == "viz_block") {
    output = <VizBlockRenderer key={controller.clock} doc={controller.doc} block={props.block} />;
  } else if (props.block.type == "table_block") {
    output = <TableBlockRenderer key={controller.clock} doc={controller.doc} block={props.block} />;
  }

  return (
    <Box>
      <Row gap="small" wrap>
        <Heading level="3">Show me:</Heading>
        {props.block.query.measures.map(measure => (
          <MeasureForm key={measure.id} block={props.block} blockIndex={props.index} measure={measure} />
        ))}
        <AddMeasureButton block={props.block} blockIndex={props.index} />
      </Row>
      <Row gap="small" wrap>
        <Heading level="3">Split by:</Heading>
        {props.block.query.dimensions.map(dimension => (
          <DimensionForm key={dimension.id} block={props.block} blockIndex={props.index} dimension={dimension} />
        ))}
        <AddDimensionButton block={props.block} blockIndex={props.index} />
      </Row>
      <Row gap="small">
        <Heading level="3">Filtering out:</Heading>
      </Row>
      <Row gap="small">
        <Heading level="3">Show as:</Heading>
        <VizTypeSelector block={props.block} blockIndex={props.index} />
      </Row>

      <Box margin={{ top: "medium" }} height="500px">
        {output}
      </Box>
    </Box>
  );
};
