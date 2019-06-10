import * as React from "react";
import _ from "lodash";
import { Field as FormikField, FastField as FormikFastField, FieldProps as FormikFieldProps } from "formik";
import ReactSelect from "react-select";
import { Props as ReactSelectProps } from "react-select/lib/Select";
import { AcceptedFormikFieldProps } from "./types";
import { InputConfigProps } from "./inputHelpers";
import { ControlWrapper } from "./ControlWrapper";
import { BoxProps } from "grommet";
import { ValueType } from "react-select/lib/types";
import { isArrayOptionType } from "../utils";
import { FlurishReactSelectTheme } from "flurishlib";

export interface SelectOptionType {
  value: string | boolean | null;
  label: string | React.ReactNode;
}

export interface SelectProps<Option extends SelectOptionType> extends AcceptedFormikFieldProps, InputConfigProps {
  options: Option[];
  label?: string;
  isMulti?: boolean;
  onChange?: (value: any) => void;
  onBlur?: (value: any) => void;
  filterOption?: ReactSelectProps<Option>["filterOption"];
  width?: BoxProps["width"];
  fast?: boolean;
}

export class Select<Option extends SelectOptionType = SelectOptionType> extends React.Component<SelectProps<Option>> {
  optionForValue(value: SelectOptionType["value"]) {
    return _.find(this.props.options, (option: SelectOptionType) => option.value === value);
  }

  render() {
    const Component = this.props.fast ? FormikFastField : FormikField;

    return (
      <Component validate={this.props.validate} name={this.props.name}>
        {({ field, form }: FormikFieldProps<any>) => {
          let selectedOption: SelectOptionType | SelectOptionType[] | undefined = undefined;

          if (this.props.isMulti && _.isArray(field.value)) {
            selectedOption = _.compact(field.value.map(value => this.optionForValue(value)));
          } else {
            selectedOption = this.optionForValue(field.value);
          }

          return (
            <ControlWrapper
              name={field.name}
              label={this.props.label}
              width={this.props.width}
              showErrorMessages={this.props.showErrorMessages}
            >
              <ReactSelect
                name={field.name}
                theme={FlurishReactSelectTheme}
                value={selectedOption}
                styles={{ container: provided => ({ ...provided, minWidth: 200 }) }}
                {...this.props}
                onChange={(option: ValueType<SelectOptionType>) => {
                  if (option) {
                    let value;
                    if (isArrayOptionType(option)) {
                      value = option.map(opt => opt.value);
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
      </Component>
    );
  }
}
