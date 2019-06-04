import React from "react";
import { Box, BoxProps } from "grommet";

export const Row = (props: BoxProps & { className?: string; children?: React.ReactNode }) => (
  <Box direction="row" align="center" alignContent="center" {...props} className={`FlurishRow ${props.className || ""}`} />
);
