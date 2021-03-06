import React from "react";
import { Helmet } from "react-helmet";
import { Box } from "grommet";

export const PageBox = (props: { children: React.ReactNode; documentTitle?: string }) => {
  React.useEffect(() => {
    analytics.page(props.documentTitle || "Auth Page");
  }, [props.documentTitle]);

  return (
    <Box fill background="light-2" align="center" justify="center">
      <Helmet>
        <title>{props.documentTitle || "Home"} - Superpro</title>
      </Helmet>
      <Box width="large" pad="medium" background="white" elevation="small">
        {props.children}
      </Box>
    </Box>
  );
};
