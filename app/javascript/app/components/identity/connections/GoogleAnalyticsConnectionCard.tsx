import React from "react";
import gql from "graphql-tag";
import { ConnectionCard } from "./ConnectionCard";
import { Button } from "grommet";
import { Add } from "app/components/common/SuperproIcons";

gql`
  fragment GoogleAnalyticsConnectionCardContent on GoogleAnalyticsCredential {
    id
    viewName
    propertyName
    accountName
  }
`;

export const GoogleAnalyticsConnectionCard = () => {
  return (
    <ConnectionCard
      name="Google Analytics"
      description="Superpro connects to [Google Analytics](https://analytics.google.com/) to import web traffic and conversion data."
      typename="GoogleAnalyticsCredential"
    >
      <Button icon={<Add />} label="Connect Google Analytics" href="/connection_auth/google_analytics_oauth" />
    </ConnectionCard>
  );
};
