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
import { HideVerboseContentPlugin } from "./HideVerboseContentPlugin";
import { ProcessEditorToolbarPlugin } from "./ProcessEditorToolbar";
// import Lists from "@convertkit/slate-lists";

export const Plugins = [
  HideVerboseContentPlugin(),
  ChecklistPlugin(),
  ExpensePlugin(),
  DeadlinesPlugin(),
  PasteLinkify(),
  CollapseOnEscape(),
  MarkHotkeys(),
  GlobalHotkeysPlugin(),
  BasicFormattingPlugin(),
  SimpleListsPlugin(),
  RichShortcutsPlugin(),
  ProcessEditorToolbarPlugin()
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
