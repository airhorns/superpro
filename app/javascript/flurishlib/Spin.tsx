import React from "react";
import { Box } from "grommet";
import { withTheme } from "styled-components";
import Loader from "react-loader-spinner";

export const Spin = withTheme((props: { theme: any }) => {
  return <Loader type="MutatingDot" color={(props.theme && props.theme.global.colors.brand) || "black"} />;
});

export const PageLoadSpin = () => (
  <Box fill justify="center" align="center">
    <Spin />
  </Box>
);
