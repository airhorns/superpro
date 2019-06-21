import RRule, { RRuleSet } from "rrule";
import { DateTime } from "luxon";
import { Scalars } from "../app-graph";

export type SerializedRRuleSet = Scalars["RecurrenceRuleString"][];

export const parseISODate = (str: string) => DateTime.fromISO(str).toJSDate();

export const serializeRRuleSet = (set: RRuleSet): SerializedRRuleSet => {
  return set.rrules().map(rrule => rrule.toString());
};

export const deserializeRRuleSet = (obj: SerializedRRuleSet): RRuleSet => {
  const set = new RRuleSet();
  obj.forEach(rule => set.rrule(RRule.fromString(rule)));
  return set;
};
