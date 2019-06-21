import * as React from "react";
import { find, isEqual } from "lodash";
import ReactSelect from "react-select";
import { ValueType } from "react-select/lib/types";
import RRule, { RRuleSet } from "rrule";
import { FieldPath, useSuperForm, pathToName, pathToClassName } from "flurishlib/superform";
import { isArrayOptionType, FlurishReactSelectTheme } from "flurishlib";
import { RecurrenceSelectCustomForm } from "./RecurrenceSelectCustomForm";
import { serializeRRuleSet, SerializedRRuleSet, deserializeRRuleSet } from "app/lib/rrules";

export interface RecurrenceSelectOptionType {
  value: SerializedRRuleSet | null;
  label: string | React.ReactNode;
  openCustomForm?: boolean;
}

const createSet = (callback: (set: RRuleSet) => void) => {
  const set = new RRuleSet();
  callback(set);
  return serializeRRuleSet(set);
};

export const DefaultOptions: RecurrenceSelectOptionType[] = [
  {
    label: "Repeats every day",
    value: createSet(set => {
      set.rrule(new RRule({ freq: RRule.DAILY, interval: 1 }));
    })
  },
  {
    label: "Repeats every month on the 1st",
    value: createSet(set => {
      set.rrule(new RRule({ freq: RRule.MONTHLY, interval: 1, bymonthday: [1] }));
    })
  },
  {
    label: "Repeats twice a month on the 1st and 15th",
    value: createSet(set => {
      // On the weekday closest to the 15th
      set.rrule(
        new RRule({
          freq: RRule.MONTHLY,
          interval: 1,
          bysetpos: -1,
          bymonthday: [13, 14, 15],
          byweekday: [RRule.MO, RRule.TU, RRule.WE, RRule.TH, RRule.FR]
        })
      );
      // On the weekday closest to the last day of the month
      set.rrule(
        new RRule({
          freq: RRule.MONTHLY,
          interval: 1,
          bysetpos: -1,
          byweekday: [RRule.MO, RRule.TU, RRule.WE, RRule.TH, RRule.FR]
        })
      );
    })
  }
];

const DoesntRepeatOption = { label: "Doesn't repeat", value: null };

const optionForValue = (options: RecurrenceSelectOptionType[], value: RecurrenceSelectOptionType["value"]) =>
  find(options, option => isEqual(option.value, value));

export interface RecurrenceSelectProps {
  path: FieldPath;
  label?: string;
  onChange?: (value: any) => void;
  onBlur?: (value: any) => void;
}

export const RecurrenceSelect = (props: RecurrenceSelectProps) => {
  const form = useSuperForm<any>();
  const [showCustomForm, setShowCustomForm] = React.useState(false);
  const customOptions: RecurrenceSelectOptionType[] = [{ value: null, label: "Other...", openCustomForm: true }];

  let selectedOption: RecurrenceSelectOptionType | undefined;
  const currentValue: SerializedRRuleSet | undefined = form.getValue(props.path);
  if (currentValue) {
    selectedOption = optionForValue(DefaultOptions, currentValue);
    if (!selectedOption) {
      selectedOption = {
        value: currentValue,
        label:
          "Repeats " +
          deserializeRRuleSet(currentValue)
            .rrules()
            .map((rule: RRule) => rule.toText())
            .join(",")
      };
      customOptions.push(selectedOption);
    }
  } else {
    selectedOption = DoesntRepeatOption;
  }

  const groupedOptions = [
    { label: null, options: [DoesntRepeatOption] },
    { label: "Simple", options: DefaultOptions },
    { label: "Custom", options: customOptions }
  ];

  return (
    <>
      <ReactSelect<RecurrenceSelectOptionType>
        name={pathToName(props.path)}
        className={`RecurrenceSelect RecurrenceSelect-${pathToClassName(props.path)}`}
        theme={FlurishReactSelectTheme}
        value={selectedOption}
        options={groupedOptions}
        isSearchable={false}
        styles={{ container: provided => ({ ...provided, minWidth: 200 }) }}
        onChange={(option: ValueType<RecurrenceSelectOptionType>) => {
          if (option) {
            if (isArrayOptionType(option)) throw new Error();
            let value = option.value;
            if (option.openCustomForm) {
              setShowCustomForm(true);
            } else {
              form.setValue(props.path, value);
              props.onChange && props.onChange(option);
            }
          }
        }}
        onBlur={e => {
          form.markTouched(props.path);
          props.onBlur && props.onBlur(e);
        }}
      />
      {showCustomForm && (
        <RecurrenceSelectCustomForm
          value={currentValue}
          setShow={setShowCustomForm}
          onSave={rruleSet => form.setValue(props.path, serializeRRuleSet(rruleSet))}
        />
      )}
    </>
  );
};
