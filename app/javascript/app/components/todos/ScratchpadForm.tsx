import React from "react";
import gql from "graphql-tag";
import { Value } from "slate";
import { Editor } from "slate-react";
import memoizeOne from "memoize-one";
import { debounce } from "lodash";
import { Anchor } from "grommet";
import { mutationSuccess, toast, Row } from "superlib";
import { SuperForm, ObjectBackend } from "superlib/superform";
import { UpdateScratchpadFromFormComponent, ScratchpadFormFragment, UpdateScratchpadFromFormMutationFn } from "app/app-graph";
import { UserCardProps, SavingNoticeState, ListPageCard } from "../common";
import { TodoEditor } from "./todo_editor/TodoEditor";

gql`
  fragment ScratchpadForm on Scratchpad {
    id
    document
    accessMode
  }

  mutation UpdateScratchpadFromForm($id: ID!, $attributes: ScratchpadAttributes!) {
    updateScratchpad(id: $id, attributes: $attributes) {
      scratchpad {
        id
        name
        updatedAt
      }
      errors {
        fullMessage
      }
    }
  }
`;

export interface ScratchpadFormProps {
  users: UserCardProps["user"][];
  scratchpad: ScratchpadFormFragment;
}

interface ScratchpadFormValues {
  scratchpad: {
    value: Value;
  };
}

export class ScratchpadForm extends React.Component<ScratchpadFormProps, SavingNoticeState> {
  state: SavingNoticeState = { lastSaveAt: null, lastChangeAt: null };
  editorRef: React.RefObject<Editor> = React.createRef();

  debouncedSave = debounce(
    async (form: ScratchpadFormValues, update: UpdateScratchpadFromFormMutationFn) => {
      const result = await update({
        variables: {
          id: this.props.scratchpad.id,
          attributes: {
            document: form.scratchpad.value.document.toJSON()
          }
        }
      });

      if (mutationSuccess(result, "updateScratchpad")) {
        this.setState({ lastSaveAt: new Date() });
      } else {
        toast.error("There was an error saving this process. Please try again.");
      }
    },
    1000,
    { leading: false }
  );

  initialValues = memoizeOne(() => {
    return {
      scratchpad: {
        value: Value.fromJSON({
          object: "value",
          document: this.props.scratchpad.document,
          data: {
            mode: "scratchpad",
            showToolbar: true,
            showOnlyCondensedTodos: false
          }
        } as any)
      }
    };
  });

  handleChange = (form: ScratchpadFormValues, update: UpdateScratchpadFromFormMutationFn) => {
    this.setState({ lastChangeAt: new Date() });
    this.debouncedSave(form, update);
  };

  render() {
    return (
      <UpdateScratchpadFromFormComponent>
        {update => (
          <SuperForm<ScratchpadFormValues>
            initialValues={this.initialValues()}
            backendClass={ObjectBackend}
            onChange={form => this.handleChange(form, update)}
          >
            {form => (
              <ListPageCard>
                <TodoEditor
                  users={this.props.users}
                  value={form.getValue("scratchpad.value")}
                  onChange={({ value }: { value: Value }) => {
                    form.setValue("scratchpad.value", value);
                  }}
                  autoFocus={false}
                  editorRef={this.editorRef}
                />
                <Row margin={{ bottom: "small" }} justify="center" gap="small">
                  <Anchor
                    {...{ disabled: true }}
                    onClick={() => this.editorRef.current && this.editorRef.current.command("markAllTodosCheckedState", true)}
                  >
                    Mark all as done
                  </Anchor>
                </Row>
              </ListPageCard>
            )}
          </SuperForm>
        )}
      </UpdateScratchpadFromFormComponent>
    );
  }
}
