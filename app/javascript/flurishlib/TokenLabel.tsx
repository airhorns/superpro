import React from "react";
import { Box, BoxProps, Text } from "grommet";

export const TokenLabel = (props: BoxProps & { color?: string; children: React.ReactNode }) => (
  <Box
    round="xsmall"
    pad="xsmall"
    border={{ size: "xsmall", style: "dashed", color: props.color || "accent-2" }}
    background="accent-2"
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
