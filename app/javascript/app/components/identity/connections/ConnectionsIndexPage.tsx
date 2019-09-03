import React from "react";
import { Page } from "../../common";
import { Box, Heading } from "grommet";
import { PlaidConnectionCard } from "./PlaidConnectionCard";
import gql from "graphql-tag";
import { GetConnectionsIndexPageComponent } from "app/app-graph";
import { ShopifyConnectionCard } from "./ShopifyConnectionCard";
import { GoogleAnalyticsConnectionCard } from "./GoogleAnalyticsConnectionCard";
import { assert, Row } from "superlib";
import { RestartConnectionSyncButton } from "./RestartConnectionSyncButton";
import { ConnectionSyncDiagram } from "./ConnectionSyncDiagram";
import { SyncConnectionNowButton } from "./SyncConnectionNowButton";

gql`
  query GetConnectionsIndexPage {
    connections {
      id
      displayName
      integration {
        __typename
        ... on ShopifyShop {
          id
          name
          shopifyDomain
          shopId
        }
      }
      supportsSync
      syncAttempts(first: 50) {
        nodes {
          id
          success
          finishedAt
        }
      }
      enabled
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
                {data.connections.map(node => {
                  return (
                    <Box pad="small" key={node.id} border="all">
                      <Heading level="3">{node.displayName}</Heading>
                      <Row>
                        {(node.enabled && "Enabled") || "Paused"}
                        {node.supportsSync && (
                          <>
                            <ConnectionSyncDiagram syncAttempts={node.syncAttempts.nodes} />
                            <SyncConnectionNowButton connection={node} />
                            <RestartConnectionSyncButton connection={node} />
                          </>
                        )}
                      </Row>
                    </Box>
                  );
                })}
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
