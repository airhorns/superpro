import React from "react";
import { Editor } from "slate-react";
import { Value } from "slate";
import { Box } from "grommet";
import { Plugins } from "./Plugins";
import { ProcessSchema } from "./ProcessSchema";
import { ProcessEditorToolbar } from "./ProcessEditorToolbar";

export interface ProcessEditorProps {
  value: Value;
  onChange: (value: Value) => void;
}

export class ProcessEditor extends React.Component<ProcessEditorProps> {
  editorRef: React.RefObject<Editor> = React.createRef();

  onChange = ({ value }: { value: Value }) => {
    this.props.onChange && this.props.onChange(value);
  };

  render() {
    return (
      <Box pad="small">
        {this.editorRef.current && <ProcessEditorToolbar editor={this.editorRef.current} />}
        <Editor
          spellCheck
          autoFocus
          schema={ProcessSchema}
          plugins={Plugins}
          value={this.props.value}
          onChange={this.onChange}
          ref={this.editorRef}
        />
      </Box>
    );
  }
}
