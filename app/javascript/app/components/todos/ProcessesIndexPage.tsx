import React from "react";
import { Button, Box, Text } from "grommet";
import { Page, UserCard, MutationTrashButton } from "../common";
import { Add } from "../common/FlurishIcons";
import gql from "graphql-tag";
import {
  GetAllProcessTemplatesComponent,
  CreateNewProcessTemplateComponent,
  CreateNewProcessTemplateMutationFn,
  GetAllProcessTemplatesQuery,
  DiscardProcessTemplateComponent,
  GetAllProcessTemplatesDocument
} from "app/app-graph";
import { Spin, mutationSuccess, toast, Link, Row, LinkButton } from "flurishlib";
import { History } from "history";
import { withRouter, RouteComponentProps } from "react-router";
import { WaterTable } from "flurishlib/WaterTable";
import { ArrayElementType } from "app/lib/types";
import { DateTime } from "luxon";

gql`
  query GetAllProcessTemplates {
    processTemplates(first: 30) {
      nodes {
        id
        key: id
        name
        creator {
          ...UserCard
        }
        lastExecution {
          id
          startedAt
          createdAt
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

  mutation DiscardProcessTemplate($id: ID!) {
    discardProcessTemplate(id: $id) {
      processTemplate {
        id
        discardedAt
      }
      errors {
        fullMessage
      }
    }
  }
`;

export const createAndVisitProcessTemplate = async (mutate: CreateNewProcessTemplateMutationFn, history: History) => {
  let success = false;
  let result;
  try {
    result = await mutate();
  } catch (e) {}

  const data = mutationSuccess(result, "createProcessTemplate");
  if (data) {
    success = true;
    history.push(`/todos/processes/${data.processTemplate.id}`);
  }

  if (!success) {
    toast.error("There was an error creating a process template. Please try again.");
  }
};

type ProcessTemplate = ArrayElementType<GetAllProcessTemplatesQuery["processTemplates"]["nodes"]>;

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
      <Page.Load component={GetAllProcessTemplatesComponent}>
        {data => (
          <Box>
            <WaterTable<ProcessTemplate>
              columns={[
                {
                  header: "Name",
                  key: "name",
                  render: processTemplate => <Link to={`/todos/processes/${processTemplate.id}`}>{processTemplate.name}</Link>
                },
                {
                  header: "Creator",
                  key: "creator",
                  render: processTemplate => <UserCard user={processTemplate.creator} link />
                },
                {
                  header: "Last Run",
                  key: "last_run",
                  render: processTemplate => {
                    if (processTemplate.lastExecution) {
                      return (
                        <>
                          <Link to={`/todos/processes/run/${processTemplate.lastExecution.id}`}>
                            {DateTime.fromISO(
                              processTemplate.lastExecution.startedAt || processTemplate.lastExecution.createdAt
                            ).toLocaleString(DateTime.DATE_FULL)}
                          </Link>
                          {!processTemplate.lastExecution.startedAt && <Text color="status-unknown">(paused)</Text>}
                        </>
                      );
                    } else {
                      return <Text>Never</Text>;
                    }
                  }
                },
                {
                  header: "",
                  key: "actions",
                  render: processTemplate => (
                    <Row gap="small">
                      <LinkButton to={`/todos/processes/${processTemplate.id}/start`} label="Run Now" />
                      <MutationTrashButton
                        mutationComponent={DiscardProcessTemplateComponent}
                        mutationProps={{
                          variables: { id: processTemplate.id },
                          refetchQueries: [{ query: GetAllProcessTemplatesDocument }]
                        }}
                        resourceName="process template"
                      />
                    </Row>
                  )
                }
              ]}
              records={data.processTemplates.nodes}
            />
          </Box>
        )}
      </Page.Load>
    </Page.Layout>
  );
});
