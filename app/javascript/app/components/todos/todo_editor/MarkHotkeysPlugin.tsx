import React from "react";
import isHotkey from "is-hotkey";
import { isFunction, isArray, isString } from "lodash";
import { Plugin } from "slate-react";

const KEYS_TO_MARKS = {
  b: "bold",
  i: "italic",
  u: "underline",
  "`": "code",
  "~": "strikethrough"
};

type NodeMatcher = (type: string) => boolean;
const normalizeMatcher = (matcher: NodeMatcher | string[] | string): NodeMatcher => {
  if (isFunction(matcher)) return matcher;
  if (isArray(matcher)) return type => matcher.includes(type);
  if (isString(matcher)) return type => type == matcher;
  throw new Error("unexpected type for matcher received");
};

export const MarkHotkeys = (opts: { ignoreIn?: NodeMatcher; onlyIn?: NodeMatcher } = {}): Plugin => {
  const ignoreIn = opts.ignoreIn && normalizeMatcher(opts.ignoreIn);
  const onlyIn = opts.onlyIn && normalizeMatcher(opts.onlyIn);

  const normalizedHotkeys = Object.entries(KEYS_TO_MARKS).map(([key, mark]) => ({
    triggerFn: isHotkey(key.includes("+") ? key : `mod+${key}`),
    mark
  }));

  return {
    onKeyDown(event, editor, next) {
      const key = normalizedHotkeys.find(({ triggerFn }) => triggerFn(event as KeyboardEvent));
      if (!key) {
        return next();
      }

      const startBlock = editor.value.startBlock;
      if (!startBlock) {
        return next();
      }

      const { type } = startBlock;
      if (onlyIn && !onlyIn(type)) {
        return next();
      }

      if (ignoreIn && ignoreIn(type)) {
        return next();
      }

      event.preventDefault();
      editor.toggleMark(key.mark);
      return;
    },
    renderMark(markProps) {
      switch (markProps.mark.type) {
        case "bold":
          return <strong>{markProps.children}</strong>;
        case "code":
          return <code>{markProps.children}</code>;
        case "italic":
          return <em>{markProps.children}</em>;
        case "strikethrough":
          return <del>{markProps.children}</del>;
        case "underline":
          return <u>{markProps.children}</u>;
      }
    }
  };
};
