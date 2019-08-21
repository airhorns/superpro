import React from "react";
import { Page } from "../../common";
import { Box } from "grommet";
import { PlaidConnectionCard } from "./PlaidConnectionCard";
import gql from "graphql-tag";
import { GetConnectionsIndexPageComponent } from "app/app-graph";
import { ShopifyConnectionCard } from "./ShopifyConnectionCard";
import { GoogleAnalyticsConnectionCard } from "./GoogleAnalyticsConnectionCard";

gql`
  query GetConnectionsIndexPage {
    plaidItems {
      nodes {
        ...PlaidConnectionCardContent
      }
    }
    shopifyShops {
      nodes {
        ...ShopifyConnectionCardContent
      }
    }
  }
`;

export default (_props: {}) => {
  return (
    <Page.Layout title="Connection Settings">
      <Page.Load component={GetConnectionsIndexPageComponent} require={["plaidItems", "shopifyShops"]}>
        {data => (
          <Box direction="row-responsive" gap="medium" wrap>
            <PlaidConnectionCard plaidItems={data.plaidItems.nodes} />
            <ShopifyConnectionCard shopifyShops={data.shopifyShops.nodes} />
            <GoogleAnalyticsConnectionCard />
          </Box>
        )}
      </Page.Load>
    </Page.Layout>
  );
};
