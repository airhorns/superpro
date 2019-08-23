import React from "react";
import gql from "graphql-tag";
import { ConnectionCard } from "./ConnectionCard";
import { Anchor, Box, Text, Heading } from "grommet";

gql`
  fragment GoogleAnalyticsConnectionCardContent on GoogleAnalyticsCredential {
    id
    viewName
    propertyName
    accountName
  }
`;

export const GoogleAnalyticsConnectionCard = (props: {
  googleAnalyticsCredentials: { id: string; accountName: string; propertyName: string; viewName: string }[];
}) => {
  return (
    <ConnectionCard
      name="Google Analytics"
      description="Superpro connects to [Google Analytics](https://analytics.google.com/) to import your order, inventory, customer, and web traffic data."
    >
      {props.googleAnalyticsCredentials.length > 0 && (
        <Box>
          <Text>Currently Connected Shops:</Text>
          <ul>
            {props.googleAnalyticsCredentials.map(credential => (
              <li key={credential.id}>
                <Heading level="5">
                  {credential.accountName} - {credential.propertyName} - {credential.viewName}
                </Heading>
              </li>
            ))}
          </ul>
        </Box>
      )}
      <Anchor href="/connection_auth/google_analytics_oauth">Connect Google Analytics</Anchor>
    </ConnectionCard>
  );
};
