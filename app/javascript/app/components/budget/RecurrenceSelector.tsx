import * as React from "react";
import _ from "lodash";
import { Field as FormikField, FieldProps as FormikFieldProps } from "formik";
import { Creatable } from "react-select";
import { BoxProps } from "grommet";
import { ValueType } from "react-select/lib/types";
import { SelectOptionType, ControlWrapper } from "flurishlib/formant";
import { isArrayOptionType } from "flurishlib";

export interface RecurrenceSelectorProps {
  name: string;
  options: SelectOptionType[];
  showErrorMessages?: boolean;
  label?: string;
  onChange?: (value: any) => void;
  onBlur?: (value: any) => void;
  width?: BoxProps["width"];
}

export class RecurrenceSelector extends React.Component<RecurrenceSelectorProps> {
  optionForValue(value: SelectOptionType["value"]) {
    return _.find(this.props.options, (option: SelectOptionType) => option.value === value);
  }

  render() {
    return (
      <FormikField validate={false} name={this.props.name}>
        {({ field, form }: FormikFieldProps<any>) => {
          const selectedOption = this.optionForValue(field.value);

          return (
            <ControlWrapper
              name={field.name}
              label={this.props.label}
              width={this.props.width}
              showErrorMessages={this.props.showErrorMessages}
            >
              <Creatable
                name={field.name}
                value={selectedOption}
                options={this.props.options}
                styles={{ container: provided => ({ ...provided, minWidth: 200 }) }}
                onChange={(option: ValueType<SelectOptionType>) => {
                  if (option) {
                    let value;
                    if (isArrayOptionType(option)) {
                      throw new Error("Recurrence selector shouldn't be a multiselect");
                    } else {
                      value = option.value;
                    }
                    form.setFieldValue(this.props.name, value);
                    this.props.onChange && this.props.onChange(option);
                  }
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
