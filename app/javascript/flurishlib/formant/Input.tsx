import * as React from "react";
import { TextInput as GrommetTextInput, TextInputProps as GrommetTextInputProps } from "grommet";
import { Field as FormikField, FieldProps as FormikFieldProps } from "formik";
import { AcceptedFormikFieldProps } from "./types";
import { InputConfigProps, propsForGrommetComponent } from "./inputHelpers";
import { ControlWrapper } from "./ControlWrapper";
import { Omit } from 'type-zoo/types';

type AcceptedGrommetTextInputProps = Omit<GrommetTextInputProps, "name" | "value">;

export interface InputProps
  extends AcceptedFormikFieldProps,
    Omit<JSX.IntrinsicElements["input"], "name" | "value" | "onSelect" | "size" | "children" | "placeholder">,
    AcceptedGrommetTextInputProps,
    InputConfigProps {
  label?: string;
}

export class Input<Values> extends React.Component<InputProps> {
  render() {
    return (
      <FormikField validate={this.props.validate} name={this.props.name}>
        {({ field }: FormikFieldProps<Values>) => {
          return (
            <ControlWrapper name={field.name} label={this.props.label} showErrorMessages={this.props.showErrorMessages}>
              <GrommetTextInput
                {...propsForGrommetComponent(this.props)}
                id={field.name}
                name={field.name}
                value={field.value || ""}
                onChange={e => {
                  field.onChange(e);
                  this.props.onChange && this.props.onChange(e);
                }}
                onBlur={e => {
                  field.onBlur(e);
                  this.props.onBlur && this.props.onBlur(e);
                }}
              />
            </ControlWrapper>
          );
        }}
      </FormikField>
    );
  }
}
