import React from "react";
import gql from "graphql-tag";
import { Value } from "slate";
import memoizeOne from "memoize-one";
import { debounce } from "lodash";
import { mutationSuccess, toast, Link, Row } from "flurishlib";
import { SuperForm, ObjectBackend } from "flurishlib/superform";
import {
  UpdateProcessExecutionTodosPageComponent,
  CondensedProcessExecutionFormFragment,
  UpdateProcessExecutionTodosPageMutationFn
} from "app/app-graph";
import { UserCardProps, SavingNoticeState, SavingNotice, ListPageCard } from "../common";
import { TodoEditor } from "./todo_editor/TodoEditor";
import { Heading, Anchor } from "grommet";
import { Editor } from "slate-react";
import pluralize from "pluralize";

gql`
  fragment CondensedProcessExecutionForm on ProcessExecution {
    id
    document
    name
  }

  mutation UpdateProcessExecutionTodosPage($id: ID!, $attributes: ProcessExecutionAttributes!) {
    updateProcessExecution(id: $id, attributes: $attributes) {
      processExecution {
        id
        updatedAt
      }
      errors {
        fullMessage
      }
    }
  }
`;

export interface CondensedProcessExecutionFormProps {
  users: UserCardProps["user"][];
  processExecution: CondensedProcessExecutionFormFragment;
}

interface CondensedProcessExecutionFormValues {
  processExecution: {
    value: Value;
  };
}

export class CondensedProcessExecutionForm extends React.Component<CondensedProcessExecutionFormProps, SavingNoticeState> {
  state: SavingNoticeState = { lastSaveAt: null, lastChangeAt: null };
  editorRef: React.RefObject<Editor> = React.createRef();

  debouncedSave = debounce(
    async (form: CondensedProcessExecutionFormValues, update: UpdateProcessExecutionTodosPageMutationFn) => {
      const result = await update({
        variables: {
          id: this.props.processExecution.id,
          attributes: {
            document: form.processExecution.value.document.toJSON()
          }
        }
      });

      if (mutationSuccess(result, "updateProcessExecution")) {
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
      processExecution: {
        value: Value.fromJSON({
          object: "value",
          document: this.props.processExecution.document,
          data: {
            mode: "execution",
            showToolbar: false,
            showOnlyCondensedTodos: true
          }
        } as any)
      }
    };
  });

  handleChange = (form: CondensedProcessExecutionFormValues, update: UpdateProcessExecutionTodosPageMutationFn) => {
    this.setState({ lastChangeAt: new Date() });
    this.debouncedSave(form, update);
  };

  render() {
    return (
      <UpdateProcessExecutionTodosPageComponent>
        {update => (
          <SuperForm<CondensedProcessExecutionFormValues>
            initialValues={this.initialValues()}
            backendClass={ObjectBackend}
            onChange={form => this.handleChange(form, update)}
          >
            {form => {
              const unrenderedDeadlineCount = (this.editorRef.current && this.editorRef.current.query("unrenderedDeadlineCount")) || 0;
              return (
                <ListPageCard
                  heading={
                    <>
                      <Heading level="3">
                        <Link to={`/todos/process/runs/${this.props.processExecution.id}`}>{this.props.processExecution.name}</Link>
                      </Heading>
                      <SavingNotice lastChangeAt={this.state.lastChangeAt} lastSaveAt={this.state.lastSaveAt} />
                    </>
                  }
                >
                  <TodoEditor
                    users={this.props.users}
                    value={form.getValue("processExecution.value")}
                    onChange={({ value }: { value: Value }) => {
                      form.setValue("processExecution.value", value);
                    }}
                    autoFocus={false}
                    editorRef={this.editorRef}
                  />
                  <Row margin={{ bottom: "small" }} justify="center" gap="small">
                    {unrenderedDeadlineCount > 0 &&
                      `plus ${unrenderedDeadlineCount} more ${pluralize("deadline", unrenderedDeadlineCount)}`}
                    <Link to={`/todos/process/runs/${this.props.processExecution.id}`}>See all details</Link>
                    <Anchor onClick={() => this.editorRef.current && this.editorRef.current.command("markAllTodosCheckedState", true)}>
                      Mark all as done
                    </Anchor>
                  </Row>
                </ListPageCard>
              );
            }}
          </SuperForm>
        )}
      </UpdateProcessExecutionTodosPageComponent>
    );
  }
}
