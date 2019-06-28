import React from "react";
import { Button } from "grommet";
import { Page } from "../common";
import { Add } from "../common/FlurishIcons";
import gql from "graphql-tag";
import { GetAllProcessTemplatesComponent, CreateNewProcessTemplateComponent, CreateNewProcessTemplateMutationFn } from "app/app-graph";
import { Spin, mutationSuccessful, toast } from "flurishlib";
import { History } from "history";
import { withRouter, RouteComponentProps } from "react-router";

gql(`
query GetAllProcessTemplates {
  processTemplates(first: 30) {
    nodes {
      id
      name
      creator {
        fullName
      }
    }
  }
}

mutation CreateNewProcessTemplate {
  createProcessTemplate {
    processTemplate {
      id
    }
    errors {
      fullMessage
    }
  }
}
`);

export const createAndVisitProcessTemplate = async (mutate: CreateNewProcessTemplateMutationFn, history: History) => {
  let success = false;
  let result;
  try {
    result = await mutate();
  } catch (e) {}

  if (mutationSuccessful(result) && result.data) {
    success = true;
    history.push(`/todos/processes/${result.data.createProcessTemplate.processTemplate.id}`);
  }

  if (!success) {
    toast.error("There was an error creating a process template. Please try again.");
  }
};

export default withRouter((props: RouteComponentProps) => {
  const [creating, setCreating] = React.useState(false);

  return (
    <Page.Layout
      title="Processes"
      headerExtra={
        <CreateNewProcessTemplateComponent>
          {mutate => (
            <Button
              label="New Process"
              disabled={creating}
              icon={creating ? <Spin width={32} height={32} /> : <Add />}
              onClick={async (event: React.MouseEvent) => {
                event.preventDefault();
                setCreating(true);
                await createAndVisitProcessTemplate(mutate, props.history);
                setCreating(false);
              }}
            />
          )}
        </CreateNewProcessTemplateComponent>
      }
    >
      <Page.Load component={GetAllProcessTemplatesComponent}>{data => JSON.stringify(data)}</Page.Load>
    </Page.Layout>
  );
});
