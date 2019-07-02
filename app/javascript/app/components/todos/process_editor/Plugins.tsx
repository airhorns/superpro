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
import { CondensedTodosPlugin } from "./CondensedTodosPlugin";
import { ProcessEditorToolbarPlugin } from "./ProcessEditorToolbar";

export const Plugins = [
  CondensedTodosPlugin(),
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
];
