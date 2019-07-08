import React from "react";
import ReactSelect from "react-select";
import { compact } from "lodash";
import { ValueType } from "react-select/lib/types";
import { useSuperForm, pathToName } from "superlib/superform";
import { BudgetFormValues } from "./BudgetForm";
import { SuperproReactSelectTheme, isArrayOptionType, ISO8601DateString } from "superlib";
import { DateTime } from "luxon";
import { Drop, Box, Calendar, Button } from "grommet";
import { setLineAsFixedValueType, setLineAsSeriesValueType } from "./commands";
import { FormClose } from "../common/SuperproIcons";

interface LineValueStyleOptionType {
  value: string;
  label: React.ReactNode;
  date?: DateTime;
}

export interface LineValueStyleSelectProps {
  path: string;
  onChange?: (option: LineValueStyleOptionType) => void;
  onBlur?: (event: React.SyntheticEvent) => void;
}

const now = DateTime.local();
const TodayFixedOption = {
  label: `Fixed on ${now.toLocaleString(DateTime.DATE_FULL)} (today)`,
  value: `fixed-${now.toISO()}`,
  date: now
};

const NewFixedDateOption = {
  label: "Fixed on a new date...",
  value: "fixed"
};

const SeriesOption = {
  label: "Changing month to month",
  value: "series"
};

export const LineValueStyleSelect = (props: LineValueStyleSelectProps) => {
  const [showDatePicker, setShowDatePicker] = React.useState(false);
  const form = useSuperForm<BudgetFormValues>();
  const ref = React.useRef<any>(null);

  const currentValue: string | undefined = form.getValue(props.path + ".type");
  let selectedOption: LineValueStyleOptionType | undefined;
  if (currentValue) {
    if (currentValue == "fixed") {
      const currentOccursAt = form.getValue(props.path + ".occursAt");
      if (currentOccursAt) {
        const currentDateTime = DateTime.fromISO(currentOccursAt);
        selectedOption = {
          value: `fixed-${currentOccursAt}`,
          label: `Fixed on ${currentDateTime.toLocaleString(DateTime.DATE_FULL)}`,
          date: currentDateTime
        };
      }
    } else if (currentValue == "series") {
      selectedOption = SeriesOption;
    }
  }

  let showTodayOption: true | undefined = true;
  if (selectedOption && selectedOption.date) {
    const daysDiff = TodayFixedOption.date.diff(selectedOption.date, ["days"]).days;
    if (daysDiff > -1 && daysDiff < 1) {
      showTodayOption = undefined;
    }
  }

  let showSeriesOption: true | undefined = true;
  if (selectedOption == SeriesOption) {
    showSeriesOption = undefined;
  }

  return (
    <Box ref={ref}>
      <ReactSelect<LineValueStyleOptionType>
        name={pathToName(props.path)}
        theme={SuperproReactSelectTheme}
        value={selectedOption}
        options={compact([selectedOption, showTodayOption && TodayFixedOption, NewFixedDateOption, showSeriesOption && SeriesOption])}
        isSearchable={false}
        styles={{ container: provided => ({ ...provided, minWidth: 200 }) }}
        onChange={(option: ValueType<LineValueStyleOptionType>) => {
          if (option) {
            if (isArrayOptionType(option)) throw new Error();
            if (option.value.startsWith("fixed")) {
              // Specific option with a date to assign
              if (option.date) {
                setLineAsFixedValueType(form, props.path, option.date.toISO());
              } else {
                // Custom date picker option
                setShowDatePicker(true);
              }
            } else if (option.value == "series") {
              setLineAsSeriesValueType(form, props.path);
            }

            props.onChange && props.onChange(option);
          }
        }}
        onBlur={e => {
          form.markTouched(props.path);
          props.onBlur && props.onBlur(e);
        }}
      />
      {showDatePicker && ref.current && (
        <Drop target={ref.current} onClickOutside={() => setShowDatePicker(false)} onEsc={() => setShowDatePicker(false)}>
          <Box pad="medium" gap="small">
            <Calendar
              size="medium"
              daysOfWeek
              onSelect={
                ((date: ISO8601DateString) => {
                  setLineAsFixedValueType(form, props.path, date);
                  setShowDatePicker(false);
                  props.onChange && props.onChange(date as any);
                }) as any
              }
            />
            <Button icon={<FormClose />} label="Cancel" onClick={() => setShowDatePicker(false)} />
          </Box>
        </Drop>
      )}
    </Box>
  );
};
