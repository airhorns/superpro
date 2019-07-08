import React from "react";
import { Page, HoverEditor } from "../common";
import { TodoEditor } from "./todo_editor/TodoEditor";
import { Row, mutationSuccess, toast, AutoAssert } from "flurishlib";
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

gql`
  query GetProcessTemplateForStart($id: ID!) {
    processTemplate(id: $id) {
      id
      name
      document
      createdAt
      updatedAt
      executionCount
    }
    ...ContextForTodoEditor
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
    value: Value;
    processTemplateId: string;
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
            name: form.processExecution.name,
            processTemplateId: form.processExecution.processTemplateId,
            document: form.processExecution.value.document.toJSON(),
            ...extra
          }
        }
      });
    } catch (e) {}

    this.setState({ saving: false });

    let data = mutationSuccess(result, "createProcessExecution");
    if (data) {
      this.props.history.push(`/todos/process/runs/${data.processExecution.id}`);
    } else {
      toast.error("There was an error saving this process. Please try again.");
    }
  };

  processDataForForm(data: AutoAssert<GetProcessTemplateForStartQuery>) {
    return {
      processExecution: {
        name: `${data.processTemplate.name} #${data.processTemplate.executionCount}`,
        processTemplateId: data.processTemplate.id,
        value: Value.fromJSON({
          object: "value",
          document: {
            ...data.processTemplate.document,
            data: { mode: "starting" }
          }
        })
      }
    };
  }

  render() {
    return (
      <Page.Load
        component={GetProcessTemplateForStartComponent}
        variables={{ id: this.props.match.params.id }}
        require={["processTemplate"]}
      >
        {data => (
          <StartProcessExecutionComponent>
            {update => (
              <SuperForm<ProcessExecutionFormValues> initialValues={this.processDataForForm(data)} backendClass={ObjectBackend}>
                {form => {
                  return (
                    <Page.Layout
                      title={
                        <Row gap="small">
                          Start Process:
                          <HoverEditor
                            value={form.getValue("processExecution.name")}
                            onChange={e => form.setValue("processExecution.name", e.target.value)}
                          />
                        </Row>
                      }
                      documentTitle={`Start Process: ${form.getValue("processExecution.name")}`}
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
                      breadcrumbs={[
                        "processDocs",
                        { text: data.processTemplate.name, path: `/todos/process/docs/${data.processTemplate.id}` }
                      ]}
                      padded={false}
                    >
                      <TodoEditor
                        readOnly={this.state.saving}
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
          </StartProcessExecutionComponent>
        )}
      </Page.Load>
    );
  }
}
