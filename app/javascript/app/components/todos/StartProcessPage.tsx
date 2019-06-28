import React from "react";
import { Page } from "../common";
import { ProcessEditor } from "./process_editor/ProcessEditor";
import { Row, mutationSuccessful, toast, AutoAssert } from "flurishlib";
import gql from "graphql-tag";
import { SuperForm, ObjectBackend } from "flurishlib/superform";
import {
  GetProcessTemplateForStartComponent,
  StartProcessExecutionComponent,
  StartProcessExecutionMutationFn,
  GetProcessTemplateForStartQuery,
  StartProcessExecutionMutationVariables
} from "app/app-graph";
import { Value } from "slate";
import { Button } from "grommet";
import { ProcessExecutionForm } from "./ProcessExecutionForm";

gql`
  query GetProcessTemplateForStart($id: ID!) {
    processTemplate(id: $id) {
      id
      name
      document
      createdAt
      updatedAt
    }
    currentUser {
      id
    }
    users {
      nodes {
        ...UserCard
      }
    }
  }

  mutation StartProcessExecution($attributes: ProcessExecutionAttributes!) {
    createProcessExecution(attributes: $attributes) {
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
    document: Value;
    ownerId: string;
  };
}

interface StartProcessPageState {
  saving: boolean;
}
export default class extends Page<{ id: string }, StartProcessPageState> {
  state: StartProcessPageState = { saving: false };

  handleSubmit = async (
    update: StartProcessExecutionMutationFn,
    form: ProcessExecutionFormValues,
    extra: Partial<StartProcessExecutionMutationVariables["attributes"]>
  ) => {
    this.setState({ saving: true });
    let result;
    try {
      result = await update({
        variables: {
          attributes: {
            ...form.processExecution,
            ...extra,
            document: form.processExecution.document.toJSON()
          }
        }
      });
    } catch (e) {}

    if (mutationSuccessful(result) && result.data && result.data.processExecution.id) {
    } else {
      toast.error("There was an error saving this process. Please try again.");
    }
    this.setState({ saving: false });
  };

  processDataForForm(data: AutoAssert<GetProcessTemplateForStartQuery>) {
    return {
      processExecution: {
        name: data.processTemplate.name,
        document: Value.fromJSON({
          ...data.processTemplate.document,
          document: {
            ...data.processTemplate.document.document,
            data: { mode: "starting" }
          }
        }),
        ownerId: data.currentUser.id
      }
    };
  }

  render() {
    return (
      <Page.Load component={GetProcessTemplateForStartComponent} variables={{ id: this.props.match.params.id }}>
        {data => (
          <StartProcessExecutionComponent>
            {update => (
              <SuperForm<ProcessExecutionFormValues> initialValues={this.processDataForForm(data)} backendClass={ObjectBackend}>
                {form => {
                  return (
                    <Page.Layout
                      title={<Row gap="small">Start Process: {data.processTemplate.name}</Row>}
                      documentTitle={`Start Process: ${data.processTemplate.name}`}
                      headerExtra={
                        <Row gap="small">
                          <Button
                            type="submit"
                            label="Start Now"
                            disabled={this.state.saving}
                            primary
                            onClick={() => this.handleSubmit(update, form.doc, { startNow: true })}
                          />
                          <Button
                            type="submit"
                            label="Save as Draft"
                            disabled={this.state.saving}
                            onClick={() => this.handleSubmit(update, form.doc, { startNow: true })}
                          />
                        </Row>
                      }
                      breadcrumbs={["processes", { text: data.processTemplate.name, path: `/todos/processes/${data.processTemplate.id}` }]}
                      padded={false}
                    >
                      <ProcessExecutionForm users={data.users.nodes} />
                      <ProcessEditor
                        readOnly={this.state.saving}
                        value={form.getValue("processExecution.document")}
                        onChange={({ value }: { value: Value }) => {
                          form.setValue("processExecution.document", value);
                        }}
                        autoFocus={false}
                      />
                    </Page.Layout>
                  );
                }}
              </SuperForm>
            )}
          </StartProcessExecutionComponent>
        )}
      </Page.Load>
    );
  }
}
