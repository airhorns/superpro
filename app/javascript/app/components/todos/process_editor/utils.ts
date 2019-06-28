import { Editor } from "slate";

export const isAuthoringMode = (editor: Editor) => editor.value.document.data.get("mode") == "authoring";
