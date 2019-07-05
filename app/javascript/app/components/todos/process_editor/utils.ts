import { Editor } from "slate";
import { Editor as ReactEditor } from "slate-react";

export const isAuthoringMode = (editor: Editor | ReactEditor) => editor.value.data.get("mode") == "authoring";
export const isExecutionMode = (editor: Editor | ReactEditor) => editor.value.data.get("mode") !== "authoring";
