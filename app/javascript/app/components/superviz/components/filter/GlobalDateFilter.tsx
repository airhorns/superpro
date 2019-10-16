import React from "react";
import { GlobalFilterController } from "./GlobalFilterController";
import { DropButton, Box, Button } from "grommet";
import { DateTime } from "luxon";

export const TimeRangeButton = (props: { start: DateTime; end: DateTime; label: string }) => {
  const controller = React.useContext(GlobalFilterController.Context);
  const onClick = React.useCallback(() => {
    controller.setFilter("start_date", "greater_than_or_equals", [props.start.toISO()]);
    controller.setFilter("end_date", "less_than_or_equals", [props.end.toISO()]);
  }, [controller, props]);

  return <Button plain label={props.label} onClick={onClick} />;
};

export const GlobalDateFilter = () => {
  const now = DateTime.local();

  return (
    <DropButton
      label="Date Range"
      dropAlign={{ top: "bottom", right: "right" }}
      dropContent={
        <Box pad="medium" background="light-1" gap="small">
          <TimeRangeButton start={now.minus({ days: 7 })} end={now} label="Last 7 Days" />
          <TimeRangeButton start={now.minus({ days: 30 })} end={now} label="Last 30 Days" />
          <TimeRangeButton start={now.minus({ months: 3 })} end={now} label="Last 3 Months" />
          <TimeRangeButton start={now.minus({ years: 1 })} end={now} label="Last Year" />
        </Box>
      }
    />
  );
};
