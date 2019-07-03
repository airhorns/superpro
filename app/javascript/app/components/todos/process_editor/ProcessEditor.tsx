import React from "react";
import { Editor, EditorProps } from "slate-react";
import { Plugins } from "./Plugins";
import { ProcessSchema } from "./ProcessSchema";
import { UserCardProps } from "app/components/common";
import "app/lib/slate";
import gql from "graphql-tag";

gql`
  fragment ContextForProcessEditor on AppQuery {
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

export interface ProcessEditorContextData {
  users: UserCardProps["user"][];
}

export const ProcessEditorContext = React.createContext<ProcessEditorContextData>({} as any);

export const ProcessEditor = (props: EditorProps & ProcessEditorContextData & { editorRef?: React.Ref<Editor> }) => {
  return (
    <ProcessEditorContext.Provider value={props}>
      <Editor ref={props.editorRef} spellCheck schema={ProcessSchema} plugins={Plugins} {...props} />
    </ProcessEditorContext.Provider>
  );
};
