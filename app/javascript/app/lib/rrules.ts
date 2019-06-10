import RRule, { RRuleSet } from "rrule";
import { DateTime } from "luxon";

export interface SerializedRRuleSet {
  rrules: string[];
  exdates: string[];
  rdates: string[];
}

export const parseISODate = (str: string) => DateTime.fromISO(str).toJSDate();

export const serializeRRuleSet = (set: RRuleSet): SerializedRRuleSet => {
  return {
    rrules: set.rrules().map(rrule => rrule.toString()),
    exdates: set.exdates().map(String),
    rdates: set.rdates().map(String)
  };
};

export const deserializeRRuleSet = (obj: SerializedRRuleSet): RRuleSet => {
  const set = new RRuleSet();
  obj.rrules.forEach(rule => set.rrule(RRule.fromString(rule)));
  obj.rdates.forEach(date => set.rdate(parseISODate(date)));
  obj.exdates.forEach(date => set.exdate(parseISODate(date)));
  return set;
};
