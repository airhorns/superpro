import React from "react";
import { Page } from "../common";
import { ProcessEditor } from "./process_editor/ProcessEditor";

export default () => {
  return (
    <Page.Layout title="Edit Process" padded={false}>
      <ProcessEditor />
    </Page.Layout>
  );
};
