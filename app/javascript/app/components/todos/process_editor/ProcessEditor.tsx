import React from "react";
import { Editor, EditorProps } from "slate-react";
import { Box } from "grommet";
import { Plugins } from "./Plugins";
import { ProcessSchema } from "./ProcessSchema";
import { ProcessEditorToolbar } from "./ProcessEditorToolbar";

export class ProcessEditor extends React.Component<EditorProps> {
  editorRef: React.RefObject<Editor> = React.createRef();

  render() {
    return (
      <Box pad="small">
        {this.editorRef.current && <ProcessEditorToolbar editor={this.editorRef.current} />}
        <Editor spellCheck schema={ProcessSchema} plugins={Plugins} ref={this.editorRef} {...this.props} />
      </Box>
    );
  }
}
