import React from "react";
import { Page, LinkButton } from "../common";
import { Add } from "../common/FlurishIcons";

export default () => {
  return (
    <Page.Layout title="Processes" headerExtra={<LinkButton to="/tasks/processes/new" label="New Process" icon={<Add />} />}></Page.Layout>
  );
};
