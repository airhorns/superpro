import React from "react";
import { Box } from "grommet";
import { Row } from "flurishlib";

export const ListPageCard = (props: { heading?: React.ReactNode; children: React.ReactNode }) => (
  <Box background="white">
    {props.heading && (
      <Row justify="between" margin={{ left: "small", bottom: "xsmall" }}>
        {props.heading}
      </Row>
    )}
    <Box>{props.children}</Box>
  </Box>
);
