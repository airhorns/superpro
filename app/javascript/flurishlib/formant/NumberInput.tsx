import * as React from "react";
import { TextInput as GrommetTextInput, TextInputProps as GrommetTextInputProps } from "grommet";
import NumberFormat, { NumberFormatProps } from "react-number-format";

import { Field as FormikField, FieldProps as FormikFieldProps } from "formik";
import { AcceptedFormikFieldProps } from "./types";
import { InputConfigProps, propsForGrommetComponent } from "./inputHelpers";
import { ControlWrapper } from "./ControlWrapper";
import { Omit } from "type-zoo/types";

type AcceptedGrommetTextInputProps = Omit<GrommetTextInputProps, "name" | "value">;

export interface NumberInputProps
  extends AcceptedFormikFieldProps,
    Omit<JSX.IntrinsicElements["input"], "name" | "value" | "onSelect" | "size" | "children" | "placeholder">,
    Pick<NumberFormatProps, "prefix" | "decimalScale" | "fixedDecimalScale">,
    AcceptedGrommetTextInputProps,
    InputConfigProps {
  label?: string;
}

export class NumberInput<Values> extends React.Component<NumberInputProps> {
  renderTextInput = (props: any) => <GrommetTextInput {...propsForGrommetComponent(this.props)} {...props} />;

  render() {
    return (
      <FormikField validate={this.props.validate} name={this.props.name}>
        {({ form, field }: FormikFieldProps<Values>) => {
          return (
            <ControlWrapper name={field.name} label={this.props.label} showErrorMessages={this.props.showErrorMessages}>
              <NumberFormat
                id={field.name}
                name={field.name}
                value={field.value}
                prefix={this.props.prefix}
                decimalScale={this.props.decimalScale}
                fixedDecimalScale={this.props.fixedDecimalScale}
                customInput={this.renderTextInput}
                onValueChange={(values: any) => {
                  form.setFieldValue(this.props.name, values.floatValue);
                  this.props.onChange && this.props.onChange({} as any);
                }}
                onBlur={(e: any) => {
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
