import React from "react";
import { DateTime } from "luxon";
import { Calendar, Box, DropButton, Text } from "grommet";
import { Calendar as CalendarIcon, FormDown } from "grommet-icons";
import { Row } from "./Row";
import { ISO8601DateString } from ".";

export interface DatePickerProps {
  value: ISO8601DateString | null;
  disabled?: boolean;
  onChange?: (newDate: ISO8601DateString) => void;
  onBlur?: (e: any) => void;
}

export class DatePicker extends React.Component<DatePickerProps, { open: boolean }> {
  constructor(props: DatePickerProps) {
    super(props);
    this.state = { open: false };
  }

  render() {
    let label = "Select a date...";
    if (this.props.value) {
      label = DateTime.fromISO(this.props.value).toLocaleString(DateTime.DATE_FULL);
    }
    return (
      <Box width="medium">
        <DropButton
          open={this.state.open}
          disabled={this.props.disabled}
          onOpen={() => this.setState({ open: true })}
          onClose={(e: any) => {
            this.setState({ open: false });
            this.props.onBlur && this.props.onBlur(e);
          }}
          dropContent={
            <Box pad="medium">
              <Calendar
                size="medium"
                daysOfWeek
                date={this.props.value || undefined}
                onSelect={
                  ((date: ISO8601DateString) => {
                    this.setState({ open: false });
                    this.props.onChange && this.props.onChange(date);
                  }) as any
                }
              />
            </Box>
          }
        >
          <Row gap="small" pad="small">
            <CalendarIcon />
            <Text>{label}</Text>
            <FormDown color="brand" />
          </Row>
        </DropButton>
      </Box>
    );
  }
}
