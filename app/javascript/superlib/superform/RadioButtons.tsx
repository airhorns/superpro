import React from "react";
import { RadioButtonGroup, RadioButtonGroupProps, BoxProps } from "grommet";
import { Omit } from "type-zoo/types";
import { FieldProps, DocType, pathToName, propsForGrommetComponent } from "./utils";
import { useSuperForm } from ".";

type AcceptedRadioButtonGroupProps = Omit<RadioButtonGroupProps, "name" | "value">;

export type RadioButtonsProps = AcceptedRadioButtonGroupProps & FieldProps;
export const FixedTypeRadioButtonGroup: React.ComponentClass<
  RadioButtonGroupProps & BoxProps & JSX.IntrinsicElements["div"]
> = (RadioButtonGroup as unknown) as any;

export const RadioButtons = <T extends DocType>(props: RadioButtonsProps) => {
  const form = useSuperForm<T>();
  const id = pathToName(props.path);

  return (
    <FixedTypeRadioButtonGroup
      id={id}
      name={id}
      value={form.getValue(props.path)}
      options={props.options}
      {...propsForGrommetComponent(props)}
      onChange={(e: React.ChangeEvent<HTMLInputElement>) => {
        form.markTouched(props.path);
        form.setValue(props.path, e.target.value);
        props.onChange && props.onChange(e);
      }}
    />
  );
};
