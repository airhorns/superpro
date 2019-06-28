import React from "react";
import { Page, HoverEditor, SavingNotice, SavingNoticeState } from "../common";
import { ProcessEditor } from "./process_editor/ProcessEditor";
import { Row, mutationSuccessful, toast } from "flurishlib";
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
    document: Value;
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
            document: doc.processTemplate.document.toJSON()
          }
        }
      });
      if (mutationSuccessful(result)) {
        this.setState({ lastSaveAt: new Date() });
      } else {
        toast.error("There was an error saving this proces. Please try again.");
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
      <Page.Load component={GetProcessTemplateForEditComponent} variables={{ id: this.props.match.params.id }}>
        {data => (
          <UpdateProcessTemplateComponent>
            {update => (
              <SuperForm<ProcessTemplateFormValues>
                initialValues={{ processTemplate: { ...data.processTemplate, document: Value.fromJSON(data.processTemplate.document) } }}
                onChange={doc => this.handleChange(update, doc)}
                backendClass={ObjectBackend}
              >
                {form => {
                  return (
                    <Page.Layout
                      title={
                        <Row gap="small">
                          Edit Process:
                          <HoverEditor
                            value={form.getValue("processTemplate.name")}
                            onChange={e => form.setValue("processTemplate.name", e.target.value)}
                          />
                        </Row>
                      }
                      documentTitle={`Edit Process: ${form.getValue("processTemplate.name")}`}
                      headerExtra={<SavingNotice lastChangeAt={this.state.lastChangeAt} lastSaveAt={this.state.lastSaveAt} />}
                      breadcrumbs={["processes"]}
                      padded={false}
                    >
                      <ProcessEditor
                        value={form.getValue("processTemplate.document")}
                        onChange={value => {
                          form.setValue("processTemplate.document", value);
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
