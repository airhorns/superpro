import React from "react";
import { Editor, Plugin } from "slate-react";
import {
  FontSize,
  BulletedList,
  CheckList,
  Undo,
  Redo,
  Bold,
  Italic,
  Underline,
  Code,
  BlockQuote,
  OrderedList,
  Deadline
} from "app/components/common/SuperproIcons";
import { Toolbar, ToolbarButton, ToolbarDivider, ToggleMarkToolbarButton, ToggleBlockToolbarButton } from "./Toolbar";
import { Box, Button } from "grommet";
import { isUndefined } from "util";
import { isExecutionMode } from "../utils";
import { InsertImageToolbarButton } from "./InsertImageToolbarButton";
import { AttachmentContainerEnum } from "app/app-graph";

export const CondensedTodosToggleButton = (props: { editor: Editor }) => {
  const text = props.editor.value.data.get("showOnlyCondensedTodos") ? "Show Instructions" : "Hide Instructions";
  return <Button plain label={text} onClick={() => props.editor.command("toggleShowOnlyCondensedTodos")} />;
};

export class TodoEditorToolbar extends React.Component<{
  editor: Editor;
  attachmentContainerId: string;
  attachmentContainerType: AttachmentContainerEnum;
  extra?: React.ReactNode;
}> {
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
        <InsertImageToolbarButton
          editor={this.props.editor}
          attachmentContainerId={this.props.attachmentContainerId}
          attachmentContainerType={this.props.attachmentContainerType}
        />
        <ToggleBlockToolbarButton type="check-list-item" icon={CheckList} editor={this.props.editor} />
        <ToolbarButton active={false} icon={Deadline} onClick={this.addDeadline} />
        <ToolbarDivider />
        {isExecutionMode(this.props.editor) && <CondensedTodosToggleButton editor={this.props.editor} />}
        <Box flex />
        {this.props.extra}
      </Toolbar>
    );
  }
}

export const TodoEditorToolbarPlugin = (options: {
  attachmentContainerId: string;
  attachmentContainerType: AttachmentContainerEnum;
  toolbarExtra?: React.ReactNode;
}): Plugin => {
  return {
    renderEditor(props, editor, next) {
      let showToolbar = editor.value.data.get("showToolbar");
      if (isUndefined(showToolbar)) showToolbar = true;

      return (
        <Box flex pad="small">
          {showToolbar && (
            <TodoEditorToolbar
              editor={(editor as unknown) as Editor}
              extra={options && options.toolbarExtra}
              attachmentContainerId={options.attachmentContainerId}
              attachmentContainerType={options.attachmentContainerType}
            />
          )}
          {next()}
        </Box>
      );
    }
  };
};
