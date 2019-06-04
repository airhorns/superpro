import React from "react";
import { Box, BoxProps, Text } from "grommet";

export const Tag = (props: BoxProps & { color?: string; children: React.ReactNode }) => (
  <Box
    round="small"
    pad="xsmall"
    border={{ size: "small", color: props.color || "accent-1" }}
    flex={false}
    fill={false}
    width="auto"
    as="span"
    style={{ display: "auto" }}
    {...props}
  >
    <Text size="small">{props.children}</Text>
  </Box>
);
