import _ from "lodash";
import * as React from "react";
import { CheckBox as GrommetCheckBox, CheckBoxProps as GrommetCheckBoxProps } from "grommet";
import { Field as FormikField, FieldProps as FormikFieldProps } from "formik";
import { AcceptedFormikFieldProps } from "./types";
import { InputConfigProps, propsForGrommetComponent } from "./inputHelpers";

type AcceptedGrommetCheckboxProps = Omit<GrommetCheckBoxProps, "name" | "value">;

export type SwitchProps = AcceptedFormikFieldProps & AcceptedGrommetCheckboxProps & InputConfigProps;

export class Switch<Values> extends React.Component<SwitchProps> {
  static defaultProps = { showErrorMessages: false };

  render() {
    return (
      <FormikField validate={this.props.validate} name={this.props.name}>
        {({ field, form }: FormikFieldProps<Values>) => {
          return (
            <GrommetCheckBox
              name={field.name}
              checked={_.isUndefined(field.value) ? false : field.value}
              onChange={(event: React.ChangeEvent<HTMLInputElement>) => {
                const value = event.target.checked;
                form.setFieldValue(field.name, value);
                this.props.onChange && this.props.onChange(value, event);
              }}
              {...propsForGrommetComponent(this.props)}
            />
          );
        }}
      </FormikField>
    );
  }
}
