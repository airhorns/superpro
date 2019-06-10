import React from "react";
import { isUndefined } from "lodash";
import { DocType, pathToName, propsForGrommetComponent } from "./utils";
import { TextInput as GrommetTextInput } from "grommet";
import { useSuperForm } from ".";
import { InputProps } from "./Input";
import NumberFormat, { NumberFormatProps } from "react-number-format";

export interface NumberInputProps extends InputProps, Pick<NumberFormatProps, "prefix" | "decimalScale" | "fixedDecimalScale"> {}

export const NumberInput = <T extends DocType>(props: NumberInputProps) => {
  const form = useSuperForm<T>();
  const id = pathToName(props.path);
  const renderTextInput = React.useMemo(() => {
    return (inputProps: any) => <GrommetTextInput {...propsForGrommetComponent(props)} type="number" {...inputProps} />;
  }, [props]);

  return (
    <NumberFormat
      id={id}
      name={id}
      value={form.getValue(props.path)}
      prefix={props.prefix}
      decimalScale={props.decimalScale}
      fixedDecimalScale={props.fixedDecimalScale}
      customInput={renderTextInput}
      onValueChange={(values: any) => {
        if (!isUndefined(values.floatValue)) {
          form.setValue(props.path, values.floatValue);
          props.onChange && props.onChange({} as any);
        }
      }}
      onBlur={(e: any) => {
        form.markTouched(props.path);
        props.onBlur && props.onBlur(e);
      }}
    />
  );
};
