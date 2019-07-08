import { Editor } from "slate";
import { Editor as ReactEditor } from "slate-react";

export const isTemplateMode = (editor: Editor | ReactEditor) => editor.value.data.get("mode") === "template";
export const isExecutionMode = (editor: Editor | ReactEditor) => editor.value.data.get("mode") === "execution";
export const isFullEditingMode = (editor: Editor | ReactEditor) =>
  editor.value.data.get("mode") === "execution" || editor.value.data.get("mode") === "scratchpad";
