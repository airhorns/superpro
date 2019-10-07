import React from "react";
import { Page } from "../common";
import { Box, Heading, Paragraph } from "grommet";
import { ConnectionsIndexContent } from "../identity/connections/ConnectionsIndexContent";

export default class ConnectionsSetupChromelessPage extends Page {
  render() {
    return (
      <Page.TakeoverLayout documentTitle="Welcome!">
        <Box align="center" pad={{ top: "large" }} gap="medium">
          <Heading>Setup your connections</Heading>
          <Paragraph textAlign="center">Connect the services you use to Superpro so your data is available for analysis.</Paragraph>
          <ConnectionsIndexContent {...this.props} />
          <Paragraph textAlign="center">
            Once your connections have been set up, Superpro will be in touch shortly about the next steps!
          </Paragraph>
        </Box>
      </Page.TakeoverLayout>
    );
  }
}
