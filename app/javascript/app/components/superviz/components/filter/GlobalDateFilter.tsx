import React from "react";
import { GlobalFilterController } from "./GlobalFilterController";
import { DropButton, Box, Button } from "grommet";
import { Duration } from "luxon";
import { find, last } from "lodash";
import { assert } from "superlib";

const KeyedTimeRanges = [
  { duration: Duration.fromObject({ days: -7 }).toISO(), label: "Last 7 Days" },
  { duration: Duration.fromObject({ days: -30 }).toISO(), label: "Last 30 Days" },
  { duration: Duration.fromObject({ months: -3 }).toISO(), label: "Last 3 Months" },
  { duration: Duration.fromObject({ years: -1 }).toISO(), label: "Last Year" },
  { duration: Duration.fromObject({ years: -2 }).toISO(), label: "Last 2 Years" },
  { duration: undefined, label: "All time" }
];

export const TimeRangeButton = (props: { duration?: string; label: string }) => {
  const controller = React.useContext(GlobalFilterController.Context);
  const onClick = React.useCallback(() => {
    if (props.duration) {
      controller.removeFilter("start_date");
      controller.removeFilter("end_date");
      controller.setFilter("duration_key", "greater_than", [props.duration]);
    } else {
      controller.removeFilter("duration_key");
    }
  }, [controller, props]);

  return <Button plain label={props.label} onClick={onClick} />;
};

export const GlobalDateFilter = () => {
  const controller = React.useContext(GlobalFilterController.Context);
  let selectedRange = assert(last(KeyedTimeRanges));
  if (controller.state.filters["duration_key"] && controller.state.filters["duration_key"].values) {
    selectedRange = assert(find(KeyedTimeRanges, ["duration", controller.state.filters["duration_key"].values[0]]));
  }

  return (
    <DropButton
      label={selectedRange.label}
      dropAlign={{ top: "bottom", right: "right" }}
      dropContent={
        <Box pad="medium" background="light-1" gap="small">
          {KeyedTimeRanges.map(({ duration, label }) => (
            <TimeRangeButton key={duration || "all_time"} duration={duration} label={label} />
          ))}
        </Box>
      }
    />
  );
};
