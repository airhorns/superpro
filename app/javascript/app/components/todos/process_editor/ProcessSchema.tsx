import { isString, isNumber, isBoolean } from "lodash";
import { SchemaProperties } from "slate";

export const ProcessSchema: SchemaProperties = {
  document: {
    data: { mode: isString }
  },
  blocks: {
    paragraph: {},
    "heading-one": {},
    "heading-two": {},
    "block-quote": {},
    image: {
      isVoid: true
    },
    "check-list-item": {},
    "expense-item": {
      data: {
        incurred: isBoolean,
        amountSubunits: isNumber
      }
    },
    deadline: {
      nodes: [{ match: { object: "inline" } }, { match: { object: "text" } }],
      data: { dueDate: () => true }
    }
  },
  inlines: {}
};
