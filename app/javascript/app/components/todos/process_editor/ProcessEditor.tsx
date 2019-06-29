import React from "react";
import { Editor, EditorProps } from "slate-react";
import { Plugins } from "./Plugins";
import { ProcessSchema } from "./ProcessSchema";

export const ProcessEditor = (props: EditorProps) => {
  return <Editor style={{ height: "100%" }} spellCheck schema={ProcessSchema} plugins={Plugins} {...props} />;
};
