import React from "react";
import { Editor, EditorProps } from "slate-react";
import { Plugins } from "./Plugins";
import { TodoSchema } from "./TodoSchema";
import { UserCardProps } from "app/components/common";
import "app/lib/slate";
import gql from "graphql-tag";

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

export const TodoEditor = (props: EditorProps & TodoEditorContextData & { editorRef?: React.Ref<Editor> }) => {
  return (
    <TodoEditorContext.Provider value={props}>
      <Editor ref={props.editorRef} spellCheck schema={TodoSchema} plugins={Plugins} {...props} />
    </TodoEditorContext.Provider>
  );
};
