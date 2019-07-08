import { isNumber, isNull, isString, isBoolean, isUndefined } from "lodash";
import { SchemaProperties } from "slate";

export const TodoSchema: SchemaProperties = {
  document: {},
  blocks: {
    paragraph: {},
    "heading-one": {},
    "heading-two": {},
    "block-quote": {},
    image: {
      isVoid: true
    },
    "check-list-item": {
      data: {
        checked: value => isUndefined(value) || isBoolean(value),
        ownerId: value => isUndefined(value) || isNull(value) || isString(value)
      }
    },
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
