import React from "react";
import { Box, BoxProps } from "grommet";
import { Omit } from "type-zoo/types";

export const Row = React.forwardRef((props: BoxProps & Omit<JSX.IntrinsicElements["div"], "instance" | "ref">, ref: any) => (
  <Box direction="row" align="center" alignContent="center" {...props} ref={ref} className={`SuperproRow ${props.className || ""}`} />
));
