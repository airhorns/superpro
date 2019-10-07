import React from "react";
import { Box, Heading, Markdown } from "grommet";
import { Row } from "superlib";
import { ConnectionGlyph, ConnectionGlyphProps } from "./ConnectionGlyph";

export const ConnectionCard = (props: {
  name: string;
  description: string;
  typename?: ConnectionGlyphProps["typename"];
  children?: React.ReactNode;
}) => {
  return (
    <Box flex={false} pad="small" width="medium" border="all" margin={{ bottom: "medium" }} gap="small">
      <Row gap="small">
        <ConnectionGlyph size="32px" typename={props.typename} />
        <Heading level="3">{props.name}</Heading>
      </Row>
      <Box>
        <Markdown>{props.description}</Markdown>
      </Box>
      {props.children}
    </Box>
  );
};
