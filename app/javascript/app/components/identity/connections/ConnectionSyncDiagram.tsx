import React from "react";
import { Row } from "superlib";
import { Box } from "grommet";
import { isUndefined, isNull } from "lodash";

export const ConnectionSyncDiagram = (props: { syncAttempts: { id: string; success?: boolean | null }[] }) => (
  <Row gap="xsmall">
    {props.syncAttempts.map(attempt => {
      let color = "red";
      if (isUndefined(attempt.success) || isNull(attempt.success)) {
        color = "grey";
      } else if (attempt.success) {
        color = "green";
      }
      return <Box key={attempt.id} width="20px" height="30px" background={color}></Box>;
    })}
  </Row>
);
