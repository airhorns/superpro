import React from "react";
import { Page } from "../../common";
import { Box, Heading } from "grommet";
import gql from "graphql-tag";
import queryString from "query-string";
import { GetConnectionsIndexPageComponent } from "app/app-graph";
import { ShopifyConnectionCard } from "./ShopifyConnectionCard";
import { GoogleAnalyticsConnectionCard } from "./GoogleAnalyticsConnectionCard";
import { ConnectionIndexEntry } from "./ConnectionIndexEntry";
import { FacebookConnectionCard } from "./FacebookConnectionCard";
import { RouteComponentProps } from "react-router";
import { toast, replaceLocationWithNewParams } from "superlib";
import { GoogleAdsConnectionCard } from "./GoogleAdsConnectionCard";
import { KlaviyoConnectionCard } from "./KlaviyoConnectionCard";
import { BrontoConnectionCard } from "./BrontoConnectionCard";

gql`
  query GetConnectionsIndexPage {
    connections {
      id
      ...ConnectionIndexEntry
    }
  }
`;

export const ConnectionsIndexContent = (props: RouteComponentProps) => {
  React.useEffect(() => {
    const params = queryString.parse(props.location.search);
    if (params.success) {
      toast.success(`${params.success} connection set up successfully!`);
      delete params.success;
      replaceLocationWithNewParams(params, props.location, props.history);
    }
  }, [props.history, props.location]);

  return (
    <Page.Load component={GetConnectionsIndexPageComponent} require={["connections"]}>
      {data => (
        <Box gap="small">
          {data.connections.length > 0 && (
            <Box>
              {data.connections.map(node => (
                <ConnectionIndexEntry key={node.id} connection={node} />
              ))}
            </Box>
          )}
          <Box gap="small">
            <Heading level="2">Add a new Connection</Heading>
            <Box direction="row-responsive" gap="medium" wrap>
              <ShopifyConnectionCard />
              <FacebookConnectionCard />
              <GoogleAdsConnectionCard />
              <GoogleAnalyticsConnectionCard />
              <KlaviyoConnectionCard />
              <BrontoConnectionCard />
            </Box>
          </Box>
        </Box>
      )}
    </Page.Load>
  );
};
