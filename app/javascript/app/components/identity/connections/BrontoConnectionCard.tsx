import React from "react";
import { ConnectionCard } from "./ConnectionCard";
import { Button } from "grommet";
import { Add } from "app/components/common/SuperproIcons";
import { Flag } from "superlib";

export const BrontoConnectionCard = () => {
  return (
    <ConnectionCard
      name="Bronto"
      description="Superpro connects to [Bronto](https://www.bronto.com) to import email marketing performance data and export customer segments."
      typename="bronto"
    >
      <Flag
        name={["feature.bronto"]}
        render={() => <Button icon={<Add />} label="Connect Bronto" href="/connection_auth/Bronto" />}
        fallbackRender={() => <Button disabled label="Coming Soon" />}
      />
    </ConnectionCard>
  );
};
