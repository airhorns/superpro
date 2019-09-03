import React from "react";
import { Row } from "superlib";
import { Box } from "grommet";

export const ConnectionSyncDiagram = (props: { syncAttempts: { id: string; success: boolean }[] }) => (
  <Row gap="xsmall">
    {props.syncAttempts.map(attempt => (
      <Box key={attempt.id} pad="small" background={attempt.success ? "green" : "red"} />
    ))}
  </Row>
);
