import React from "react";
import { Page } from "../../common";
import { Box, Heading } from "grommet";
import gql from "graphql-tag";
import { GetConnectionsIndexPageComponent } from "app/app-graph";
import { ShopifyConnectionCard } from "./ShopifyConnectionCard";
import { GoogleAnalyticsConnectionCard } from "./GoogleAnalyticsConnectionCard";
import { ConnectionIndexEntry } from "./ConnectionIndexEntry";

gql`
  query GetConnectionsIndexPage {
    connections {
      id
      ...ConnectionIndexEntry
    }
  }
`;

export default (props: {}) => {
  console.log(props);
  return (
    <Page.Layout title="Connection Settings">
      <Page.Load component={GetConnectionsIndexPageComponent} require={["connections"]}>
        {data => (
          <Box>
            {data.connections.length > 0 && (
              <Box margin={{ bottom: "small" }}>
                {data.connections.map(node => (
                  <ConnectionIndexEntry key={node.id} connection={node} />
                ))}
              </Box>
            )}
            <Heading level="2">Add a new Connection</Heading>
            <Box direction="row-responsive" gap="medium" wrap>
              <ShopifyConnectionCard />
              <GoogleAnalyticsConnectionCard />
            </Box>
          </Box>
        )}
      </Page.Load>
    </Page.Layout>
  );
};
