import React from "react";
import { Page, HoverEditor, SavingNotice, SavingNoticeState } from "../common";
import { TodoEditor } from "./todo_editor/TodoEditor";
import { Row, mutationSuccess, toast, LinkButton } from "flurishlib";
import gql from "graphql-tag";
import { SuperForm, ObjectBackend } from "flurishlib/superform";
import { GetProcessTemplateForEditComponent, UpdateProcessTemplateMutationFn, UpdateProcessTemplateComponent } from "app/app-graph";
import { Value } from "slate";
import { debounce } from "lodash";

gql`
  query GetProcessTemplateForEdit($id: ID!) {
    processTemplate(id: $id) {
      id
      name
      document
      createdAt
      updatedAt
    }
    ...ContextForTodoEditor
  }

  mutation UpdateProcessTemplate($id: ID!, $attributes: ProcessTemplateAttributes!) {
    updateProcessTemplate(id: $id, attributes: $attributes) {
      processTemplate {
        id
        updatedAt
      }
      errors {
        fullMessage
      }
    }
  }
`;

interface ProcessTemplateFormValues {
  processTemplate: {
    name: string;
    value: Value;
  };
}

export default class extends Page<{ id: string }, SavingNoticeState> {
  state: SavingNoticeState = { lastSaveAt: null, lastChangeAt: null };

  debouncedSave = debounce(
    async (doc: ProcessTemplateFormValues, update: UpdateProcessTemplateMutationFn) => {
      const result = await update({
        variables: {
          id: this.props.match.params.id,
          attributes: {
            name: doc.processTemplate.name,
            document: doc.processTemplate.value.document.toJSON()
          }
        }
      });
      if (mutationSuccess(result, "updateProcessTemplate")) {
        this.setState({ lastSaveAt: new Date() });
      } else {
        toast.error("There was an error saving this process. Please try again.");
      }
    },
    1000,
    { leading: false }
  );

  handleChange = (update: UpdateProcessTemplateMutationFn, form: ProcessTemplateFormValues) => {
    this.setState({ lastChangeAt: new Date() });
    this.debouncedSave(form, update);
  };

  render() {
    return (
      <Page.Load
        component={GetProcessTemplateForEditComponent}
        variables={{ id: this.props.match.params.id }}
        require={["processTemplate"]}
      >
        {data => (
          <UpdateProcessTemplateComponent>
            {update => (
              <SuperForm<ProcessTemplateFormValues>
                initialValues={{
                  processTemplate: {
                    ...data.processTemplate,
                    value: Value.fromJSON({
                      object: "value",
                      document: data.processTemplate.document,
                      data: { mode: "template" }
                    } as any)
                  }
                }}
                onChange={doc => this.handleChange(update, doc)}
                backendClass={ObjectBackend}
              >
                {form => {
                  return (
                    <Page.Layout
                      title={
                        <Row gap="small">
                          Edit Process Doc:
                          <HoverEditor
                            value={form.getValue("processTemplate.name")}
                            onChange={e => form.setValue("processTemplate.name", e.target.value)}
                          />
                        </Row>
                      }
                      documentTitle={`Edit Process Doc: ${form.getValue("processTemplate.name")}`}
                      headerExtra={
                        <Row gap="small">
                          <SavingNotice lastChangeAt={this.state.lastChangeAt} lastSaveAt={this.state.lastSaveAt} />
                          <LinkButton to={`/todos/process/docs/${data.processTemplate.id}/start`} label="Run Now" />
                        </Row>
                      }
                      breadcrumbs={["processDocs"]}
                      padded={false}
                    >
                      <TodoEditor
                        autoFocus
                        users={data.users.nodes}
                        value={form.getValue("processTemplate.value")}
                        onChange={({ value }: { value: Value }) => {
                          form.setValue("processTemplate.value", value);
                        }}
                      />
                    </Page.Layout>
                  );
                }}
              </SuperForm>
            )}
          </UpdateProcessTemplateComponent>
        )}
      </Page.Load>
    );
  }
}
