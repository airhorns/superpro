import React from "react";
import { ConnectionCard } from "./ConnectionCard";
import { Button } from "grommet";
import { Add } from "app/components/common/SuperproIcons";
import { Flag } from "superlib";

export const KlaviyoConnectionCard = () => {
  return (
    <ConnectionCard
      name="Klaviyo"
      description="Superpro connects to [Klaviyo](https://www.klaviyo.com) to import email marketing performance data and export customer segments."
      typename="klaviyo"
    >
      <Flag
        name={["feature.klaviyo"]}
        render={() => <Button icon={<Add />} label="Connect Klaviyo" href="/connection_auth/klaviyo" />}
        fallbackRender={() => <Button disabled label="Coming Soon" />}
      />
    </ConnectionCard>
  );
};
