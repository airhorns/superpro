import React from "react";
import { FieldProps, DocType } from "./utils";
import { useSuperForm } from "../superform";
import { DatePicker, DatePickerProps } from "superlib/DatePicker";
import { Omit } from "type-zoo/types";

export interface SuperDatePickerProps extends FieldProps, Omit<DatePickerProps, "value"> {}

export const SuperDatePicker = <T extends DocType>(props: SuperDatePickerProps) => {
  const form = useSuperForm<T>();

  return (
    <DatePicker
      value={form.getValue(props.path)}
      onChange={date => {
        form.setValue(props.path, date);
        props.onChange && props.onChange(date);
      }}
      onBlur={e => {
        form.markTouched(props.path);
        props.onBlur && props.onBlur(e);
      }}
    />
  );
};
