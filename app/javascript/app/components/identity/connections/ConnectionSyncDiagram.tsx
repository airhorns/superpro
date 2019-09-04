import React from "react";
import { Row } from "superlib";
import { DropButton, Box } from "grommet";
import { isUndefined, isNull, sortBy } from "lodash";

export const ConnectionSyncDiagram = (props: {
  syncAttempts: { id: string; success?: boolean | null; finishedAt?: string | null; startedAt: string; failureReason?: string | null }[];
}) => (
  <Row gap="xsmall">
    {sortBy(props.syncAttempts, "startedAt").map(attempt => {
      let color = "red";
      let text = "Failed";
      if (isUndefined(attempt.success) || isNull(attempt.success)) {
        text = "Unknown";
        color = "grey";
      } else if (attempt.success) {
        text = "Succeeded";
        color = "green";
      }
      return (
        <DropButton
          key={attempt.id}
          plain
          dropAlign={{ top: "bottom" }}
          {...{ style: { width: "20px", height: "30px", backgroundColor: color } }}
          dropContent={
            <Box pad="small">
              Success: {text} <br />
              Started at: {attempt.startedAt} <br />
              Finshed at: {attempt.finishedAt} <br />
              Failure reason: {attempt.failureReason}
            </Box>
          }
        />
      );
    })}
  </Row>
);
