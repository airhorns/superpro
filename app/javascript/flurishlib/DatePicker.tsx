import React from "react";
import { format } from "date-fns";
import { Calendar, Box, DropButton, Text } from "grommet";
import { Calendar as CalendarIcon, FormDown } from "grommet-icons";
import { Row } from "./Row";
import { ISO8601Date, DefaultDateFormat } from ".";

export interface DatePickerProps {
  value: ISO8601Date | null;
  disabled?: boolean;
  onChange?: (newDate: ISO8601Date) => void;
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
      label = format(this.props.value, DefaultDateFormat);
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
                  ((date: ISO8601Date) => {
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
