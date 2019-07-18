import React from "react";
import gql from "graphql-tag";
import { ToolbarButton } from "./Toolbar";
import { Trash } from "app/components/common/SuperproIcons";
import { useToolbarDiscardScratchpadMutation, GetMyTodosDocument } from "app/app-graph";
import { mutationSuccess, toast } from "superlib";

gql`
  mutation ToolbarDiscardScratchpad($id: ID!) {
    discardScratchpad(id: $id) {
      scratchpad {
        id
        discardedAt
      }
      errors {
        fullMessage
      }
    }
  }
`;

export const TrashScratchpadButton = (props: { id: string; onDiscard?: () => void }) => {
  const discardScratchpad = useToolbarDiscardScratchpadMutation({ refetchQueries: [{ query: GetMyTodosDocument }] });
  return (
    <ToolbarButton
      icon={Trash}
      active={false}
      onClick={async () => {
        let success = false;
        let result;
        try {
          result = await discardScratchpad({ variables: { id: props.id } });
        } catch (e) {}

        const data = mutationSuccess(result, "discardScratchpad");
        if (data) {
          success = true;
          props.onDiscard && props.onDiscard();
          toast.success("Scratchpad successfully trashed.");
        }

        if (!success) {
          toast.error("There was an error trashing this scratchpad. Please try again.");
        }
      }}
    />
  );
};
