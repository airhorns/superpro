import React from "react";
import { compact } from "lodash";
import { Page, SavingNoticeState, SavingNotice, UserCard, HoverEditor } from "../common";
import { ProcessEditor } from "./process_editor/ProcessEditor";
import { mutationSuccess, toast, AutoAssert, Row } from "flurishlib";
import gql from "graphql-tag";
import { SuperForm, ObjectBackend, FieldBox, Select } from "flurishlib/superform";
import {
  GetProcessExecutionForRunComponent,
  UpdateProcessExecutionComponent,
  UpdateProcessExecutionMutationFn,
  GetProcessExecutionForRunQuery
} from "app/app-graph";
import { Value } from "slate";
import { debounce } from "lodash";
import { Box, CheckBox } from "grommet";

gql`
  query GetProcessExecutionForRun($id: ID!) {
    processExecution(id: $id) {
      id
      name
      document
      owner {
        id
      }
      processTemplate {
        id
        name
      }
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
    document: Value;
    ownerId: string;
  };
}

interface RunProcessPageState extends SavingNoticeState {
  showVerboseContent: boolean;
}

export default class extends Page<{ id: string }, RunProcessPageState> {
  state: RunProcessPageState = { lastSaveAt: null, lastChangeAt: null, showVerboseContent: false };

  debouncedSave = debounce(
    async (doc: ProcessExecutionFormValues, update: UpdateProcessExecutionMutationFn) => {
      const result = await update({
        variables: {
          id: this.props.match.params.id,
          attributes: {
            document: doc.processExecution.document.toJSON()
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
        document: Value.fromJSON({
          object: "value",
          document: data.processExecution.document,
          data: { mode: "configuration", showVerboseContent: this.state.showVerboseContent } as any
        }),
        ownerId: data.processExecution.owner && data.processExecution.owner.id
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
                      <Box pad="small">
                        <FieldBox label="Owner" path="processExecution.ownerId">
                          <Select
                            path="processExecution.ownerId"
                            options={data.users.nodes.map(user => ({
                              value: user.id,
                              label: <UserCard user={user} />
                            }))}
                          ></Select>
                        </FieldBox>
                        <CheckBox
                          label="Show Instructions"
                          toggle
                          checked={this.state.showVerboseContent}
                          onChange={(e: React.ChangeEvent<HTMLInputElement>) => {
                            this.setState({ showVerboseContent: e.target.checked });
                          }}
                        />
                      </Box>
                      <ProcessEditor
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
          </UpdateProcessExecutionComponent>
        )}
      </Page.Load>
    );
  }
}
