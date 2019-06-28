import React from "react";
import { Page } from "../common";
import { ProcessEditor } from "./process_editor/ProcessEditor";
import { HoverEditor } from "../common/HoverEditor";
import { Row } from "flurishlib";

export default () => {
  const [name, setName] = React.useState("Example Process");

  return (
    <Page.Layout
      title={
        <Row gap="small">
          Edit Process:
          <HoverEditor value={name} onChange={e => setName(e.target.value)} />
        </Row>
      }
      documentTitle={`Edit Process: ${name}`}
      breadcrumbs={["processes"]}
      padded={false}
    >
      <ProcessEditor />
    </Page.Layout>
  );
};
