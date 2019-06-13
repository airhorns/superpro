import React from "react";
import { isUndefined } from "lodash";
import { DocType, pathToName, propsForGrommetComponent } from "./utils";
import { TextInput as GrommetTextInput } from "grommet";
import { useSuperForm } from ".";
import { InputProps } from "./Input";
import NumberFormat, { NumberFormatProps } from "react-number-format";

export interface NumberInputProps extends InputProps, Pick<NumberFormatProps, "prefix" | "decimalScale" | "fixedDecimalScale"> {}

// this should be using the propsForGrommetComponent helper to propagate props from the NumberInput props to the Grommet Input component, but, I couldn't get it to do that while not causing the NumberInput.customInput value to change all the time, which caused the input to lose focus every rerender.
const GrommetizedInput = (props: any) => <GrommetTextInput {...props} />;

export const NumberInput = <T extends DocType>(props: NumberInputProps) => {
  const form = useSuperForm<T>();
  const id = pathToName(props.path);
  const grommetProps = propsForGrommetComponent(props);
  return (
    <NumberFormat
      id={id}
      name={id}
      value={form.getValue(props.path)}
      prefix={props.prefix}
      decimalScale={props.decimalScale}
      fixedDecimalScale={props.fixedDecimalScale}
      customInput={GrommetizedInput}
      onValueChange={(values: any) => {
        let value: any;
        if (isUndefined(values.floatValue)) {
          value = null;
        } else {
          value = values.floatValue;
        }
        form.setValue(props.path, value);
        props.onChange && props.onChange({} as any);
      }}
      onBlur={(e: any) => {
        form.markTouched(props.path);
        props.onBlur && props.onBlur(e);
      }}
      {...grommetProps}
    />
  );
};
