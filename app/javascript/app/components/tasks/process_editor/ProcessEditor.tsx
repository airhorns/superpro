import React from "react";
import { Editor } from "slate-react";
import { Value } from "slate";
import { Plugins } from "./Plugins";
import { Toolbar, ToggleMarkToolbarButton, ToggleBlockToolbarButton, ToolbarButton, ToolbarDivider } from "./Toolbar";
import { Box, Button } from "grommet";
import {
  Bold,
  Italic,
  Underline,
  Code,
  FontSize,
  OrderedList,
  CheckList,
  BulletedList,
  BlockQuote,
  Undo,
  Redo,
  Add
} from "app/components/common/FlurishIcons";
import { ProcessSchema } from "./ProcessSchema";
import { Row } from "flurishlib";

// Create our initial value...
const initialValue = Value.fromJSON({
  document: {
    nodes: [
      {
        object: "block",
        type: "stage",
        data: { title: "Stage 1" },
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
    ]
  }
} as any);

interface ProcessEditorState {
  value: Value;
}

export class ProcessEditor extends React.Component<{}, ProcessEditorState> {
  // Set the initial value when the app is first constructed.
  state: ProcessEditorState = {
    value: initialValue
  };

  editorRef: React.RefObject<Editor> = React.createRef();

  // On change, update the app's React state with the new editor value.
  onChange = ({ value }: { value: Value }) => {
    console.debug(value.toJSON());
    this.setState({ value });
  };

  undo = (event: React.SyntheticEvent) => {
    event.preventDefault();
    this.editorRef.current && this.editorRef.current.undo();
  };

  redo = (event: React.SyntheticEvent) => {
    event.preventDefault();
    this.editorRef.current && this.editorRef.current.redo();
  };

  addStage = () => {
    this.editorRef.current && this.editorRef.current.command("addStage", this.editorRef.current);
  };

  // Render the editor.
  render() {
    return (
      <Box background="light-1">
        {this.editorRef.current && (
          <Toolbar>
            <ToolbarButton active={false} icon={Undo} onClick={this.undo} />
            <ToolbarButton active={false} icon={Redo} onClick={this.redo} />
            <ToolbarDivider />
            <ToggleMarkToolbarButton type="bold" icon={Bold} editor={this.editorRef.current} />
            <ToggleMarkToolbarButton type="italic" icon={Italic} editor={this.editorRef.current} />
            <ToggleMarkToolbarButton type="underlined" icon={Underline} editor={this.editorRef.current} />
            <ToggleMarkToolbarButton type="code" icon={Code} editor={this.editorRef.current} />
            <ToggleBlockToolbarButton type="block-quote" icon={BlockQuote} editor={this.editorRef.current} />
            <ToolbarDivider />
            <ToggleBlockToolbarButton type="heading-one" icon={FontSize} editor={this.editorRef.current} />
            <ToggleBlockToolbarButton type="numbered-list" icon={OrderedList} editor={this.editorRef.current} />
            <ToggleBlockToolbarButton type="bulleted-list" icon={BulletedList} editor={this.editorRef.current} />
            <ToggleBlockToolbarButton type="check-list-item" icon={CheckList} editor={this.editorRef.current} />
          </Toolbar>
        )}
        <Editor
          spellCheck
          autoFocus
          schema={ProcessSchema}
          plugins={Plugins}
          value={this.state.value}
          onChange={this.onChange}
          ref={this.editorRef}
        />
        <Row pad="small">
          <Button label="Add Stage" icon={<Add />} onClick={this.addStage} />
        </Row>
      </Box>
    );
  }
}
