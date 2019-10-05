import React from "react";
import { Page, LinkButton } from "../common";
import { TakeoverPageLayout } from "../common/TakeoverPageLayout";
import { Box, Heading, Paragraph } from "grommet";

export default class WelcomePage extends Page {
  render() {
    return (
      <TakeoverPageLayout documentTitle="Welcome!">
        <Box align="center" pad={{ top: "large" }} gap="medium">
          <Heading>Welcome to Superpro!</Heading>
          <Paragraph textAlign="center">
            Superpro is <b>your</b> personal data analyst to help you build an even more amazing business. Please pardon the mess as we
            continue to building this alpha product.
            <br />
            <br />
            To get setup with Superpro, please set up your connections!
          </Paragraph>
          <LinkButton primary to="/s/connection_setup" label="Go to Connections" />
        </Box>
      </TakeoverPageLayout>
    );
  }
}
