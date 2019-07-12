import React from "react";
import { Page } from "../../common";
import { Box } from "grommet";
import { PlaidConnectionCard } from "./PlaidConnectionCard";
import { ConnectionCard } from "./ConnectionCard";

export default (_props: {}) => {
  return (
    <Page.Layout title="Connection Settings">
      <Box direction="row-responsive" gap="medium" wrap>
        <PlaidConnectionCard />
        <ConnectionCard name="Xero Accounting" description="Xero is a blah blah blah" />
        <ConnectionCard name="Quickbooks Accounting" description="QBO is a blah blah blah" />
      </Box>
    </Page.Layout>
  );
};
