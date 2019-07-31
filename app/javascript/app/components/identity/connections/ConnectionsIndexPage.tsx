import React from "react";
import { Page } from "../../common";
import { Box } from "grommet";
import { PlaidConnectionCard } from "./PlaidConnectionCard";
import { ConnectionCard } from "./ConnectionCard";
import gql from "graphql-tag";
import { GetConnectionsIndexPageComponent } from "app/app-graph";
import { ShopifyConnectionCard } from "./ShopifyConnectionCard";

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
            <ConnectionCard name="Xero Accounting" description="Coming soon!" />
            <ConnectionCard name="Quickbooks Accounting" description="Coming soon!" />
          </Box>
        )}
      </Page.Load>
    </Page.Layout>
  );
};
