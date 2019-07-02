import React from "react";
import { compact } from "lodash";
import { Page, SavingNoticeState, SavingNotice, HoverEditor } from "../common";
import { ProcessEditor } from "./process_editor/ProcessEditor";
import { mutationSuccess, toast, AutoAssert, Row } from "flurishlib";
import gql from "graphql-tag";
import { SuperForm, ObjectBackend } from "flurishlib/superform";
import {
  GetProcessExecutionForRunComponent,
  UpdateProcessExecutionComponent,
  UpdateProcessExecutionMutationFn,
  GetProcessExecutionForRunQuery
} from "app/app-graph";
import { Value } from "slate";
import { debounce } from "lodash";

gql`
  query GetProcessExecutionForRun($id: ID!) {
    processExecution(id: $id) {
      id
      name
      document
      processTemplate {
        id
        name
      }
      createdAt
      updatedAt
    }
    ...ContextForProcessEditor
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
        toast.error("There was an error saving this process. Please try again.");
      }
    },
    1000,
    { leading: false }
  );

  handleChange = (update: UpdateProcessExecutionMutationFn, form: ProcessExecutionFormValues) => {
    this.setState({ lastChangeAt: new Date() });
    this.debouncedSave(form, update);
  };

  processDataForForm(data: AutoAssert<GetProcessExecutionForRunQuery>) {
    return {
      processExecution: {
        name: data.processExecution.name,
        value: Value.fromJSON({
          object: "value",
          document: data.processExecution.document,
          data: { mode: "configuration" } as any
        })
      }
    };
  }

  render() {
    return (
      <Page.Load component={GetProcessExecutionForRunComponent} variables={{ id: this.props.match.params.id }}>
        {data => (
          <UpdateProcessExecutionComponent>
            {update => (
              <SuperForm<ProcessExecutionFormValues>
                initialValues={this.processDataForForm(data)}
                backendClass={ObjectBackend}
                onChange={doc => this.handleChange(update, doc)}
              >
                {form => {
                  return (
                    <Page.Layout
                      title={
                        <Row gap="small">
                          Process:
                          <HoverEditor
                            value={form.getValue("processExecution.name")}
                            onChange={e => form.setValue("processExecution.name", e.target.value)}
                          />
                        </Row>
                      }
                      documentTitle={`Start Process: ${form.getValue("processExecution.name")}`}
                      headerExtra={<SavingNotice lastChangeAt={this.state.lastChangeAt} lastSaveAt={this.state.lastSaveAt} />}
                      breadcrumbs={compact([
                        "processes",
                        data.processExecution.processTemplate && {
                          text: data.processExecution.processTemplate.name,
                          path: `/todos/processes/${data.processExecution.processTemplate.id}`
                        }
                      ])}
                      padded={false}
                    >
                      <ProcessEditor
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
