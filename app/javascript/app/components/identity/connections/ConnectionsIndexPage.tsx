import React from "react";
import { Page } from "../../common";
import { Box } from "grommet";
import { PlaidConnectionCard } from "./PlaidConnectionCard";
import { ConnectionCard } from "./ConnectionCard";
import gql from "graphql-tag";
import { GetConnectionsIndexPageComponent } from "app/app-graph";

gql`
  query GetConnectionsIndexPage {
    plaidItems {
      nodes {
        ...PlaidConnectionCardContent
      }
    }
  }
`;

export default (_props: {}) => {
  return (
    <Page.Layout title="Connection Settings">
      <Page.Load component={GetConnectionsIndexPageComponent} require={["plaidItems"]}>
        {data => (
          <Box direction="row-responsive" gap="medium" wrap>
            <PlaidConnectionCard plaidItems={data.plaidItems.nodes} />
            <ConnectionCard name="Xero Accounting" description="Coming soon!" />
            <ConnectionCard name="Quickbooks Accounting" description="Coming soon!" />
          </Box>
        )}
      </Page.Load>
    </Page.Layout>
  );
};
