import React from "react";
import { ListPageCard } from "../common";
import { Heading, Box } from "grommet";

export const Scratchpad = (_props: {}) => {
  return (
    <ListPageCard heading={<Heading level="3">Scratchpad</Heading>}>
      <Box pad="large"></Box>
    </ListPageCard>
  );
};
