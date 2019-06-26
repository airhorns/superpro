import { isString } from "lodash";
import { SchemaProperties } from "slate";

export const ProcessSchema: SchemaProperties = {
  document: {
    nodes: [{ match: { type: "stage" }, min: 1 }]
  },
  blocks: {
    stage: {
      data: { title: isString },
      nodes: [{ match: { object: "block" } }]
    },
    paragraph: {},
    "heading-one": {},
    "heading-two": {},
    "block-quote": {},
    image: {
      isVoid: true
    },
    "check-list-item": {}
  }
};
