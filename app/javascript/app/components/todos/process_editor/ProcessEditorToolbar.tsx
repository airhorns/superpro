import React from "react";
import { Editor, Plugin } from "slate-react";
import {
  FontSize,
  BulletedList,
  CheckList,
  Expense,
  Undo,
  Redo,
  Bold,
  Italic,
  Underline,
  Code,
  BlockQuote,
  OrderedList,
  Deadline
} from "app/components/common/FlurishIcons";
import { Toolbar, ToolbarButton, ToolbarDivider, ToggleMarkToolbarButton, ToggleBlockToolbarButton } from "./Toolbar";
import { Box } from "grommet";

export class ProcessEditorToolbar extends React.Component<{ editor: Editor }> {
  undo = (event: React.SyntheticEvent) => {
    event.preventDefault();
    this.props.editor.undo();
  };

  redo = (event: React.SyntheticEvent) => {
    event.preventDefault();
    this.props.editor.redo();
  };

  addDeadline = (event: React.SyntheticEvent) => {
    event.preventDefault();
    this.props.editor.command("addDeadline");
  };

  render() {
    return (
      <Toolbar>
        <ToolbarButton active={false} icon={Undo} onClick={this.undo} />
        <ToolbarButton active={false} icon={Redo} onClick={this.redo} />
        <ToolbarDivider />
        <ToggleMarkToolbarButton type="bold" icon={Bold} editor={this.props.editor} />
        <ToggleMarkToolbarButton type="italic" icon={Italic} editor={this.props.editor} />
        <ToggleMarkToolbarButton type="underlined" icon={Underline} editor={this.props.editor} />
        <ToggleMarkToolbarButton type="code" icon={Code} editor={this.props.editor} />
        <ToggleBlockToolbarButton type="block-quote" icon={BlockQuote} editor={this.props.editor} />
        <ToolbarDivider />
        <ToggleBlockToolbarButton type="heading-one" icon={FontSize} editor={this.props.editor} />
        <ToggleBlockToolbarButton type="numbered-list" icon={OrderedList} editor={this.props.editor} />
        <ToggleBlockToolbarButton type="bulleted-list" icon={BulletedList} editor={this.props.editor} />
        <ToolbarDivider />
        <ToggleBlockToolbarButton type="check-list-item" icon={CheckList} editor={this.props.editor} />
        <ToggleBlockToolbarButton
          type="expense-item"
          icon={Expense}
          editor={this.props.editor}
          newBlockData={{ amountSubunits: 0, incurred: false }}
        />
        <ToolbarButton active={false} icon={Deadline} onClick={this.addDeadline} />
      </Toolbar>
    );
  }
}

export const ProcessEditorToolbarPlugin = (): Plugin => {
  return {
    renderEditor(props, editor, next) {
      return (
        <Box flex pad="small">
          <ProcessEditorToolbar editor={editor as any} />
          {next()}
        </Box>
      );
    }
  };
};
