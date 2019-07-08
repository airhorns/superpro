import * as React from "react";
import { find, compact, isArray } from "lodash";
import ReactSelect from "react-select";
import { Props as ReactSelectProps } from "react-select/lib/Select";
import { ValueType } from "react-select/lib/types";
import { isArrayOptionType } from "../utils";
import { FieldProps, DocType, pathToName, pathToClassName } from "./utils";
import { useSuperForm } from "../superform";
import { SuperproReactSelectTheme } from "superlib/SuperproTheme";

export interface SelectOptionType {
  value: string | number | boolean | null;
  label: string | React.ReactNode;
}

export interface SelectProps<Option extends SelectOptionType> extends FieldProps {
  options: Option[];
  label?: string;
  isMulti?: boolean;
  onChange?: (value: any) => void;
  onBlur?: (value: any) => void;
  filterOption?: ReactSelectProps<Option>["filterOption"];
}

export const optionForValue = (options: SelectOptionType[], value: SelectOptionType["value"]) => find(options, { value: value });

export const Select = <T extends DocType, Option extends SelectOptionType = SelectOptionType>(props: SelectProps<Option>) => {
  const form = useSuperForm<T>();

  let selectedOption: SelectOptionType | SelectOptionType[] | undefined = undefined;
  const currentValue = form.getValue(props.path);

  if (props.isMulti && isArray(currentValue)) {
    selectedOption = compact(currentValue.map(value => optionForValue(props.options, value)));
  } else {
    selectedOption = optionForValue(props.options, currentValue);
  }

  return (
    <ReactSelect
      name={pathToName(props.path)}
      className={`SuperSelect SuperSelect-${pathToClassName(props.path)}`}
      theme={SuperproReactSelectTheme}
      value={selectedOption}
      styles={{ container: provided => ({ ...provided, minWidth: 200 }) }}
      filterOption={props.filterOption}
      options={props.options}
      onChange={(option: ValueType<SelectOptionType>) => {
        if (option) {
          let value;
          if (isArrayOptionType(option)) {
            value = option.map(opt => opt.value);
          } else {
            value = option.value;
          }
          form.setValue(props.path, value);
          props.onChange && props.onChange(option);
        }
      }}
      onBlur={e => {
        form.markTouched(props.path);
        props.onBlur && props.onBlur(e);
      }}
    />
  );
};
