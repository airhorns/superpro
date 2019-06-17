import React from "react";
import { isUndefined, isNumber } from "lodash";
import { DocType, pathToName, propsForGrommetComponent } from "./utils";
import { TextInput as GrommetTextInput } from "grommet";
import { useSuperForm } from ".";
import { InputProps } from "./Input";
import NumberFormat, { NumberFormatProps } from "react-number-format";

export interface NumberInputProps
  extends InputProps,
    Pick<NumberFormatProps, "prefix" | "decimalScale" | "fixedDecimalScale" | "displayType"> {
  storeAsSubunits?: boolean; // useful for currency inputs where the subunits should be stored instead of a float with decimal places
}

export const NumberInput = <T extends DocType>(props: NumberInputProps) => {
  const form = useSuperForm<T>();
  const id = pathToName(props.path);

  let value = form.getValue(props.path);
  if (props.storeAsSubunits && isNumber(props.decimalScale)) {
    value = value / 10 ** props.decimalScale;
  }

  return (
    <NumberFormat
      id={id}
      name={id}
      value={value}
      prefix={props.prefix}
      decimalScale={props.decimalScale}
      fixedDecimalScale={props.fixedDecimalScale}
      customInput={GrommetTextInput}
      onValueChange={(values: any) => {
        let value: any;
        if (isUndefined(values.floatValue)) {
          value = null;
        } else {
          value = values.floatValue;
        }

        if (props.storeAsSubunits && isNumber(props.decimalScale)) {
          value = value * 10 ** props.decimalScale;
        }

        form.setValue(props.path, value);
        props.onChange && props.onChange({} as any);
      }}
      onBlur={(e: any) => {
        form.markTouched(props.path);
        props.onBlur && props.onBlur(e);
      }}
      // NumberFormat passes through unrecognized props to the customInput component, so this allows things like the plain prop to make it down to the Grommet component and style it
      {...propsForGrommetComponent(props)}
    />
  );
};
