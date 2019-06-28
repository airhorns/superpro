import React from "react";
import { Page } from "../common";
import { ProcessEditor } from "./process_editor/ProcessEditor";
import { HoverEditor } from "../common/HoverEditor";
import { Row } from "flurishlib";
import gql from "graphql-tag";
import { SuperForm } from "flurishlib/superform";
import { GetProcessTemplateForEditComponent } from "app/app-graph";

gql`
  query GetProcessTemplateForEdit($id: ID!) {
    processTemplate(id: $id) {
      name
      document
    }
  }
`;

interface ProcessTemplateFormValues {
  processTemplate: {
    name: string;
    document: any;
  };
}

export default class extends Page<{ id: string }> {
  render() {
    return (
      <Page.Load component={GetProcessTemplateForEditComponent} variables={{ id: this.props.match.params.id }}>
        {data => (
          <SuperForm<ProcessTemplateFormValues> initialValues={{ processTemplate: data.processTemplate }}>
            {form => (
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
                breadcrumbs={["processes"]}
                padded={false}
              >
                <ProcessEditor onChange={value => form.setValue("processTemplate.document", value.toJSON())} />
              </Page.Layout>
            )}
          </SuperForm>
        )}
      </Page.Load>
    );
  }
}
