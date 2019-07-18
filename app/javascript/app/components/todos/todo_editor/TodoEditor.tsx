import React from "react";
import { Editor, EditorProps } from "slate-react";
import PasteLinkify from "slate-paste-linkify";
import CollapseOnEscape from "slate-collapse-on-escape";
import { ChecklistPlugin } from "./plugins/ChecklistPlugin";
import { MarkHotkeys } from "./plugins/MarkHotkeysPlugin";
import { SimpleListsPlugin } from "./plugins/SimpleListsPlugin";
import { DeadlinesPlugin } from "./plugins/DeadlinesPlugin";
import { BasicFormattingPlugin } from "./plugins/BasicFormattingPlugin";
import { GlobalHotkeysPlugin } from "./plugins/GlobalHotkeysPlugin";
import { RichShortcutsPlugin } from "./plugins/RichShortcutsPlugin";
import { CondensedTodosPlugin } from "./plugins/CondensedTodosPlugin";
import { TodoEditorToolbarPlugin } from "./toolbar/TodoEditorToolbar";
import { RerenderPlugin } from "./plugins/RerenderPlugin";

import { TodoSchema } from "./TodoSchema";
import { UserCardProps } from "app/components/common";
import "app/lib/slate";
import gql from "graphql-tag";
import { PasteAndDropFilesPlugin } from "./plugins/PasteAndDropFilesPlugin";
import { AttachmentContainerEnum } from "app/app-graph";
import { RenderAttachmentsPlugin } from "./plugins/RenderAttachmentsPlugin";

gql`
  fragment ContextForTodoEditor on AppQuery {
    users {
      nodes {
        ...UserCard
      }
    }
    currentUser {
      id
    }
  }
`;

export interface TodoEditorContextData {
  users: UserCardProps["user"][];
}

export const TodoEditorContext = React.createContext<TodoEditorContextData>({} as any);

export const TodoEditor = (
  props: EditorProps &
    TodoEditorContextData & {
      attachmentContainerType: AttachmentContainerEnum;
      attachmentContainerId: string;
      toolbarExtra?: React.ReactNode;
      editorRef?: React.Ref<Editor>;
    }
) => {
  const { toolbarExtra, editorRef, users, attachmentContainerId, attachmentContainerType, ...rest } = props;

  const plugins = React.useMemo(() => {
    return [
      CondensedTodosPlugin(),
      ChecklistPlugin(),
      DeadlinesPlugin(),
      PasteLinkify(),
      CollapseOnEscape(),
      MarkHotkeys(),
      GlobalHotkeysPlugin(),
      BasicFormattingPlugin(),
      SimpleListsPlugin(),
      RichShortcutsPlugin(),
      RenderAttachmentsPlugin(),
      PasteAndDropFilesPlugin({ attachmentContainerId, attachmentContainerType }),
      TodoEditorToolbarPlugin({ attachmentContainerId, attachmentContainerType, toolbarExtra }),
      RerenderPlugin()
    ];
  }, [toolbarExtra, attachmentContainerId, attachmentContainerType]);

  return (
    <TodoEditorContext.Provider value={{ users }}>
      <Editor ref={editorRef} spellCheck schema={TodoSchema} plugins={plugins} {...rest} />
    </TodoEditorContext.Provider>
  );
};
