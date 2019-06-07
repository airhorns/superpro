import React from "react";
import { TextInput as GrommetTextInput, TextInputProps as GrommetTextInputProps } from "grommet";
import { Omit } from "type-zoo/types";
import { FieldProps, DocType, pathToName } from "./utils";
import { useSuperForm } from ".";

type AcceptedGrommetTextInputProps = Omit<GrommetTextInputProps, "name" | "value">;

export interface InputProps
  extends Omit<JSX.IntrinsicElements["input"], "name" | "value" | "onSelect" | "size" | "children" | "placeholder">,
    AcceptedGrommetTextInputProps,
    FieldProps {}

export const Input = <T extends DocType>(props: InputProps) => {
  const form = useSuperForm<T>();
  const id = pathToName(props.path);

  return (
    <GrommetTextInput
      id={id}
      name={id}
      value={form.getValue(props.path)}
      onChange={e => {
        form.setValue(props.path, e.target.value || "");
        props.onChange && props.onChange(e);
      }}
      onBlur={e => {
        form.markTouched(props.path);
        props.onBlur && props.onBlur(e);
      }}
    />
  );
};
