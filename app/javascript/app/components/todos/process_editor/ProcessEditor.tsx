import React from "react";
import { Editor } from "slate-react";
import { Value } from "slate";
import { Plugins } from "./Plugins";
import { Box } from "grommet";
import { ProcessSchema } from "./ProcessSchema";
import { ProcessEditorToolbar } from "./ProcessEditorToolbar";

const initialValue = Value.fromJSON({
  document: {
    data: {
      mode: "authoring"
    },
    nodes: [
      {
        object: "block",
        type: "paragraph",
        nodes: [
          {
            object: "text",
            text: "A line of text in a paragraph."
          }
        ]
      }
    ]
  }
} as any);

export interface ProcessEditorProps {
  onChange?: (value: Value) => void;
}
interface ProcessEditorState {
  value: Value;
}

export class ProcessEditor extends React.Component<ProcessEditorProps, ProcessEditorState> {
  state: ProcessEditorState = {
    value: initialValue
  };

  editorRef: React.RefObject<Editor> = React.createRef();

  onChange = ({ value }: { value: Value }) => {
    console.debug(value);
    this.setState({ value }, () => {
      this.props.onChange && this.props.onChange(this.state.value);
    });
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
          value={this.state.value}
          onChange={this.onChange}
          ref={this.editorRef}
        />
      </Box>
    );
  }
}
