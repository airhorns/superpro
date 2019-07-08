import React from "react";
import { compact } from "lodash";
import { Box, Button, Anchor, Text } from "grommet";
import { Value } from "slate";
import { debounce } from "lodash";
import { DateTime } from "luxon";
import { Page, SavingNoticeState, SavingNotice, HoverEditor } from "../common";
import { TodoEditor } from "./todo_editor/TodoEditor";
import { mutationSuccess, toast, AutoAssert, Row, ISO8601DateString } from "flurishlib";
import gql from "graphql-tag";
import { SuperForm, ObjectBackend } from "flurishlib/superform";
import {
  GetProcessExecutionForEditComponent,
  UpdateProcessExecutionComponent,
  UpdateProcessExecutionMutationFn,
  GetProcessExecutionForEditQuery
} from "app/app-graph";

gql`
  query GetProcessExecutionForEdit($id: ID!) {
    processExecution(id: $id) {
      id
      name
      startedAt
      document
      processTemplate {
        id
        name
      }
      createdAt
      updatedAt
    }
    ...ContextForTodoEditor
  }

  mutation UpdateProcessExecution($id: ID!, $attributes: ProcessExecutionAttributes!) {
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

interface ProcessExecutionFormValues {
  processExecution: {
    name: string;
    startedAt: ISO8601DateString | null | undefined;
    value: Value;
  };
}

export default class extends Page<{ id: string }, SavingNoticeState> {
  state: SavingNoticeState = { lastSaveAt: null, lastChangeAt: null };

  debouncedSave = debounce(
    async (doc: ProcessExecutionFormValues, update: UpdateProcessExecutionMutationFn) => {
      const result = await update({
        variables: {
          id: this.props.match.params.id,
          attributes: {
            document: doc.processExecution.value.document.toJSON()
          }
        }
      });
      if (mutationSuccess(result, "updateProcessExecution")) {
        this.setState({ lastSaveAt: new Date() });
      } else {
        toast.error("There was an error saving this process run. Please try again.");
      }
    },
    1000,
    { leading: false }
  );

  handleChange = (update: UpdateProcessExecutionMutationFn, form: ProcessExecutionFormValues) => {
    this.setState({ lastChangeAt: new Date() });
    this.debouncedSave(form, update);
  };

  processDataForForm(data: AutoAssert<GetProcessExecutionForEditQuery>) {
    return {
      processExecution: {
        name: data.processExecution.name,
        startedAt: data.processExecution.startedAt,
        value: Value.fromJSON({
          object: "value",
          document: data.processExecution.document,
          data: {
            mode: "execution",
            showToolbar: true
          } as any
        })
      }
    };
  }

  render() {
    return (
      <Page.Load
        component={GetProcessExecutionForEditComponent}
        variables={{ id: this.props.match.params.id }}
        require={["processExecution"]}
      >
        {data => (
          <UpdateProcessExecutionComponent>
            {update => (
              <SuperForm<ProcessExecutionFormValues>
                initialValues={this.processDataForForm(data)}
                backendClass={ObjectBackend}
                onChange={doc => this.handleChange(update, doc)}
              >
                {form => {
                  const startedAt = form.getValue("processExecution.startedAt");
                  return (
                    <Page.Layout
                      title={
                        <Box>
                          <Row gap="small">
                            Process Run:
                            <HoverEditor
                              value={form.getValue("processExecution.name")}
                              onChange={e => form.setValue("processExecution.name", e.target.value)}
                            />
                          </Row>
                          {startedAt && (
                            <Text size="small">
                              Started at: {DateTime.fromISO(startedAt).toLocaleString(DateTime.DATETIME_FULL)}
                              &nbsp;
                              <Anchor onClick={() => form.setValue("processExecution.startedAt", null)}>Return to draft</Anchor>
                            </Text>
                          )}
                        </Box>
                      }
                      documentTitle={`Process Run: ${form.getValue("processExecution.name")}`}
                      headerExtra={
                        <Row gap="small">
                          <SavingNotice lastChangeAt={this.state.lastChangeAt} lastSaveAt={this.state.lastSaveAt} />
                          {!startedAt && (
                            <Button
                              type="submit"
                              label="Start Now"
                              primary
                              onClick={() => form.setValue("processExecution.startedAt", DateTime.local().toISO())}
                            />
                          )}
                        </Row>
                      }
                      breadcrumbs={compact([
                        "processRuns",
                        data.processExecution.processTemplate && {
                          text: data.processExecution.processTemplate.name,
                          path: `/todos/process/docs/${data.processExecution.processTemplate.id}`
                        }
                      ])}
                      padded={false}
                    >
                      <TodoEditor
                        users={data.users.nodes}
                        value={form.getValue("processExecution.value")}
                        onChange={({ value }: { value: Value }) => {
                          form.setValue("processExecution.value", value);
                        }}
                        autoFocus={false}
                      />
                    </Page.Layout>
                  );
                }}
              </SuperForm>
            )}
          </UpdateProcessExecutionComponent>
        )}
      </Page.Load>
    );
  }
}
