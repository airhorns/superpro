import { ChecklistPlugin } from "./ChecklistPlugin";
import PasteLinkify from "slate-paste-linkify";
import { MarkHotkeys } from "./MarkHotkeysPlugin";
import { SimpleListsPlugin } from "./SimpleLists";
import { StagesPlugin } from "./StagesPlugin";
import { BasicFormattingPlugin } from "./BasicFormattingPlugin";
// import Lists from "@convertkit/slate-lists";

/* eslint-disable @typescript-eslint/camelcase */
export const Plugins = [
  ChecklistPlugin(),
  StagesPlugin(),
  PasteLinkify(),
  MarkHotkeys(),
  BasicFormattingPlugin(),
  SimpleListsPlugin()
  // Lists({
  //   blocks: {
  //     ordered_list: "ordered-list",
  //     unordered_list: "unordered-list",
  //     list_item: "list-item"
  //   },
  //   classNames: {
  //     ordered_list: "ordered-list",
  //     unordered_list: "unordered-list",
  //     list_item: "list-item"
  //   }
  // })
];
