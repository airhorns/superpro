import { isNull, isString, isBoolean, isUndefined } from "lodash";
import { SchemaProperties } from "slate";

export const TodoSchema: SchemaProperties = {
  document: {},
  blocks: {
    paragraph: {},
    "heading-one": {},
    "heading-two": {},
    "block-quote": {},
    "check-list-item": {
      data: {
        checked: value => isUndefined(value) || isBoolean(value),
        ownerId: value => isUndefined(value) || isNull(value) || isString(value)
      }
    },
    deadline: {
      nodes: [{ match: { object: "inline" } }, { match: { object: "text" } }],
      data: { dueDate: () => true }
    },
    image: {
      isVoid: true
    },
    "file-attachment": {
      isVoid: true
    },
    "file-placeholder": {
      isVoid: true
    }
  },
  inlines: {}
};
