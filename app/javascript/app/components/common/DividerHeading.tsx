import React from "react";
import { Box, Heading } from "grommet";
import { Row } from "../../../flurishlib";

export interface DividerProps {
  children: React.ReactNode;
}

export const DividerHeading = (props: DividerProps) => (
  <Box direction="row" align="center" margin={{ vertical: "small" }} flex={false}>
    <Box flex border={{ side: "bottom", size: "xsmall", color: "light-1" }} height="50%" />
    <Box pad={{ horizontal: "small" }} direction="row" align="center" alignContent="center">
      <Heading level="4" margin={"none"}>
        <Row gap="small">{props.children}</Row>
      </Heading>
    </Box>
    <Box flex border={{ side: "bottom", size: "xsmall", color: "light-1" }} height="50%" />
  </Box>
);
