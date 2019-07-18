import React from "react";
import { Editor, EditorProps } from "slate-react";
import PasteLinkify from "slate-paste-linkify";
import CollapseOnEscape from "slate-collapse-on-escape";
import { ChecklistPlugin } from "./ChecklistPlugin";
import { MarkHotkeys } from "./MarkHotkeysPlugin";
import { SimpleListsPlugin } from "./SimpleLists";
import { DeadlinesPlugin } from "./DeadlinesPlugin";
import { BasicFormattingPlugin } from "./BasicFormattingPlugin";
import { GlobalHotkeysPlugin } from "./GlobalHotkeysPlugin";
import { RichShortcutsPlugin } from "./RichShortcutsPlugin";
import { CondensedTodosPlugin } from "./CondensedTodosPlugin";
import { TodoEditorToolbarPlugin } from "./TodoEditorToolbar";
import { RerenderPlugin } from "./RerenderPlugin";

import { TodoSchema } from "./TodoSchema";
import { UserCardProps } from "app/components/common";
import "app/lib/slate";
import gql from "graphql-tag";
import { InsertFilesPlugin } from "./InsertFilesPlugin";
import { AttachmentContainerEnum } from "app/app-graph";
import { RenderAttachmentsPlugin } from "./RenderAttachmentsPlugin";

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
      InsertFilesPlugin({ attachmentContainerId, attachmentContainerType }),
      TodoEditorToolbarPlugin({ toolbarExtra }),
      RerenderPlugin()
    ];
  }, [toolbarExtra, attachmentContainerId, attachmentContainerType]);

  return (
    <TodoEditorContext.Provider value={{ users }}>
      <Editor ref={editorRef} spellCheck schema={TodoSchema} plugins={plugins} {...rest} />
    </TodoEditorContext.Provider>
  );
};
