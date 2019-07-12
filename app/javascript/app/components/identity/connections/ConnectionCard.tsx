import React from "react";
import { Box, Heading, Markdown } from "grommet";
import { Row } from "superlib";

export const ConnectionCard = (props: { name: string; description: string; children?: React.ReactNode }) => {
  return (
    <Box flex={false} pad="small" width="medium" border="all" margin={{ bottom: "medium" }} gap="small">
      <Row>
        <Heading level="3">{props.name}</Heading>
      </Row>
      <Box>
        <Markdown>{props.description}</Markdown>
      </Box>
      {props.children}
    </Box>
  );
};
