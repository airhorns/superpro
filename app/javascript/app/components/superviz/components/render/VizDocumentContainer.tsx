import React from "react";
import { Box } from "grommet";

export const VizDocumentContainer = (props: { children: React.ReactNode }) => {
  return (
    <Box fill gap="large">
      {props.children}
    </Box>
  );
};
