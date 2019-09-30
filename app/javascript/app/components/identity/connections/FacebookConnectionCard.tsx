import React from "react";
import { ConnectionCard } from "./ConnectionCard";
import { Button } from "grommet";
import { Add } from "app/components/common/SuperproIcons";

export const FacebookConnectionCard = () => {
  return (
    <ConnectionCard
      name="Facebook"
      description="Superpro connects to [Facebook](https://facebook.com/) to import your Facebook and Instagram advertising data."
    >
      <Button icon={<Add />} label="Connect Facebook" href="/connection_auth/facebook" />
    </ConnectionCard>
  );
};
