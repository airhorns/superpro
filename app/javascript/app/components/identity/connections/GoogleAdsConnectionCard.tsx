import React from "react";
import { ConnectionCard } from "./ConnectionCard";
import { Button } from "grommet";
import { Add } from "app/components/common/SuperproIcons";
import { Flag } from "superlib";

export const GoogleAdsConnectionCard = () => {
  return (
    <ConnectionCard
      name="Google Ads"
      description="Superpro connects to [Google Ads](https://ads.google.com) to import marketing performance data from campaigns on Google's ad platforms."
      typename="google-ads"
    >
      <Flag
        name={["feature.googleAds"]}
        render={() => <Button icon={<Add />} label="Connect Google" href="/connection_auth/google_ads" />}
        fallbackRender={() => <Button disabled label="Coming Soon" />}
      />
    </ConnectionCard>
  );
};
