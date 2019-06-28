import PasteLinkify from "slate-paste-linkify";
import CollapseOnEscape from "slate-collapse-on-escape";
import { ChecklistPlugin } from "./ChecklistPlugin";
import { MarkHotkeys } from "./MarkHotkeysPlugin";
import { SimpleListsPlugin } from "./SimpleLists";
import { DeadlinesPlugin } from "./DeadlinesPlugin";
import { BasicFormattingPlugin } from "./BasicFormattingPlugin";
import { ExpensePlugin } from "./ExpensePlugin";
import { GlobalHotkeysPlugin } from "./GlobalHotkeysPlugin";
import { RichShortcutsPlugin } from "./RichShortcutsPlugin";
// import Lists from "@convertkit/slate-lists";

export const Plugins = [
  ChecklistPlugin(),
  ExpensePlugin(),
  DeadlinesPlugin(),
  PasteLinkify(),
  CollapseOnEscape(),
  MarkHotkeys(),
  GlobalHotkeysPlugin(),
  BasicFormattingPlugin(),
  SimpleListsPlugin(),
  RichShortcutsPlugin()
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
