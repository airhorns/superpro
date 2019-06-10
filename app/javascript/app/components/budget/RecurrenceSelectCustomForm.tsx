import React from "react";
import { DateTime } from "luxon";
import { RRule, Frequency, RRuleSet } from "rrule";
import pluralize from "pluralize";
import { Box, Heading, RadioButtonGroup, Text, Button } from "grommet";
import { SerializedRRuleSet } from "app/lib/rrules";
import { SimpleModalOverlay } from "../common";
import { SuperForm, NumberInput, Select, SuperDatePicker } from "flurishlib/superform";
import { Row, ISO8601DateString } from "flurishlib";

export interface RecurrenceSelectCustomFormProps {
  value: SerializedRRuleSet | undefined;
  setShow: (open: boolean) => void;
  onSave: (rruleSet: RRuleSet) => void;
}

interface CustomRecurrenceFormValues {
  freq: Frequency;
  interval: number;
  until?: ISO8601DateString;
  count?: number;
  dtstart: ISO8601DateString;
}

const parseIfPresent = (str: ISO8601DateString | undefined) => (str ? DateTime.fromISO(str).toJSDate() : undefined);

export const RecurrenceSelectCustomForm = (props: RecurrenceSelectCustomFormProps) => {
  return (
    <SimpleModalOverlay setShow={props.setShow}>
      <SuperForm<CustomRecurrenceFormValues> initialValues={{ freq: RRule.WEEKLY, interval: 1, dtstart: DateTime.local().toISO() }}>
        {form => {
          let endingValue = "never";
          if (form.doc.until) {
            endingValue = "on_date";
          } else if (form.doc.count) {
            endingValue = "after_occurrences";
          }
          const formatFrequency = (str: string) => (form.doc.interval > 1 ? pluralize(str) : str);

          return (
            <Box pad="small">
              <Heading level="3">Custom repeat</Heading>
              <Row pad="small" gap="small">
                <Text>Repeat every</Text>
                <Box width="xsmall">
                  <NumberInput path="interval" />
                </Box>
                <Box width="small">
                  <Select
                    path="freq"
                    options={[
                      { value: RRule.DAILY, label: formatFrequency("Day") },
                      { value: RRule.WEEKLY, label: formatFrequency("Week") },
                      { value: RRule.MONTHLY, label: formatFrequency("Month") }
                    ]}
                  />
                </Box>
              </Row>
              <Box gap="small">
                <Text>Ends</Text>
                <RadioButtonGroup
                  name="limit"
                  options={[
                    { value: "never", label: "Never" },
                    { value: "after_occurrences", label: "After..." },
                    { value: "on_date", label: "On..." }
                  ]}
                  value={endingValue}
                  onChange={(event: React.ChangeEvent<any>) => {
                    const value = event.target.value;
                    form.dispatch(doc => {
                      delete doc.until;
                      delete doc.count;
                      switch (value) {
                        case "after_occurrences": {
                          doc.count = 5;
                          break;
                        }
                        case "on_date": {
                          const start = DateTime.fromISO(doc.dtstart);
                          let end;
                          if (doc.freq == RRule.DAILY) {
                            end = start.plus({ days: 7 });
                          } else if (doc.freq == RRule.WEEKLY) {
                            end = start.plus({ weeks: 4 });
                          } else if (doc.freq == RRule.MONTHLY) {
                            end = start.plus({ months: 6 });
                          } else {
                            throw new Error("Unconfigured frequency default for recurrence stop date");
                          }
                          doc.until = end.toISO();
                          break;
                        }
                      }
                    });
                  }}
                />
                {endingValue == "after_occurrences" && (
                  <Row pad="small" gap="small">
                    <Text>After</Text>
                    <NumberInput path="count" />
                    <Text>occurrences</Text>
                  </Row>
                )}
                {endingValue == "on_date" && (
                  <Row pad="small" gap="small">
                    <Text>Until</Text>
                    <SuperDatePicker path="until" />
                  </Row>
                )}
              </Box>
              <Row justify="between" pad={{ top: "medium" }}>
                <Button
                  primary
                  label="Save"
                  onClick={() => {
                    const set = new RRuleSet();
                    set.rrule(
                      new RRule({
                        freq: form.doc.freq,
                        interval: form.doc.interval,
                        count: form.doc.count,
                        dtstart: parseIfPresent(form.doc.dtstart),
                        until: parseIfPresent(form.doc.until)
                      })
                    );
                    props.onSave(set);
                    props.setShow(false);
                  }}
                />
              </Row>
            </Box>
          );
        }}
      </SuperForm>
    </SimpleModalOverlay>
  );
};
