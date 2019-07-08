import React from "react";
import { Button, Box, Text } from "grommet";
import { Page, MutationTrashButton } from "../common";
import { Add, CheckList, Deadline } from "../common/SuperproIcons";
import gql from "graphql-tag";
import {
  GetAllProcessExecutionsComponent,
  CreateNewProcessExecutionComponent,
  CreateNewProcessExecutionMutationFn,
  GetAllProcessExecutionsQuery,
  DiscardProcessExecutionComponent,
  GetAllProcessExecutionsDocument
} from "app/app-graph";
import { Spin, mutationSuccess, toast, Link, Row } from "superlib";
import { History } from "history";
import { withRouter, RouteComponentProps } from "react-router";
import { WaterTable } from "superlib/WaterTable";
import { ArrayElementType } from "app/lib/types";
import { UserAvatarList } from "../common/UserAvatarList";
import { DateTime } from "luxon";

gql`
  query GetAllProcessExecutions {
    processExecutions(first: 30) {
      nodes {
        id
        key: id
        name
        startedAt
        openTodoCount
        closedTodoCount
        totalTodoCount
        closestFutureDeadline
        involvedUsers {
          ...UserCard
        }
      }
    }
  }

  mutation CreateNewProcessExecution {
    createProcessExecution {
      processExecution {
        id
      }
      errors {
        fullMessage
      }
    }
  }

  mutation DiscardProcessExecution($id: ID!) {
    discardProcessExecution(id: $id) {
      processExecution {
        id
        discardedAt
      }
      errors {
        fullMessage
      }
    }
  }
`;

export const createAndVisitProcessExecution = async (mutate: CreateNewProcessExecutionMutationFn, history: History) => {
  let success = false;
  let result;
  try {
    result = await mutate();
  } catch (e) {}

  const data = mutationSuccess(result, "createProcessExecution");
  if (data) {
    success = true;
    history.push(`/todos/process/runs/${data.processExecution.id}`);
  }

  if (!success) {
    toast.error("There was an error creating this process run. Please try again.");
  }
};

type ProcessExecution = ArrayElementType<GetAllProcessExecutionsQuery["processExecutions"]["nodes"]>;

export default withRouter((props: RouteComponentProps) => {
  const [creating, setCreating] = React.useState(false);

  return (
    <Page.Layout
      title="Process Runs"
      headerExtra={
        <CreateNewProcessExecutionComponent>
          {mutate => (
            <Button
              label="New Run"
              disabled={creating}
              icon={creating ? <Spin width={32} height={32} /> : <Add />}
              onClick={async (event: React.MouseEvent) => {
                event.preventDefault();
                setCreating(true);
                await createAndVisitProcessExecution(mutate, props.history);
                setCreating(false);
              }}
            />
          )}
        </CreateNewProcessExecutionComponent>
      }
    >
      <Page.Load component={GetAllProcessExecutionsComponent}>
        {data => (
          <Box>
            <WaterTable<ProcessExecution>
              columns={[
                {
                  header: "Name",
                  key: "name",
                  render: processExecution => <Link to={`/todos/process/runs/${processExecution.id}`}>{processExecution.name}</Link>
                },
                {
                  header: "Started",
                  key: "started",
                  render: processExecution => {
                    if (processExecution.startedAt) {
                      return DateTime.fromISO(processExecution.startedAt).toLocaleString(DateTime.DATETIME_FULL);
                    } else {
                      return <Text color="status-unknown">Draft</Text>;
                    }
                  }
                },
                {
                  header: "Progress",
                  key: "progress",
                  render: processExecution => (
                    <Box>
                      <Text>
                        <CheckList size="small" />
                        &nbsp;
                        {processExecution.totalTodoCount > 0
                          ? `${processExecution.openTodoCount} / ${processExecution.totalTodoCount} todos done`
                          : "No todos"}
                      </Text>
                      {processExecution.closestFutureDeadline && (
                        <Text>
                          <Deadline size="small" />
                          &nbsp;Next deadline: {DateTime.fromISO(processExecution.closestFutureDeadline).toLocaleString(DateTime.DATE_FULL)}
                        </Text>
                      )}
                    </Box>
                  )
                },
                {
                  header: "People",
                  key: "users",
                  render: processExecution => <UserAvatarList users={processExecution.involvedUsers} />
                },
                {
                  header: "",
                  key: "actions",
                  render: processExecution => (
                    <Row gap="small">
                      <MutationTrashButton
                        mutationComponent={DiscardProcessExecutionComponent}
                        mutationProps={{
                          variables: { id: processExecution.id },
                          refetchQueries: [{ query: GetAllProcessExecutionsDocument }]
                        }}
                        resourceName="process template"
                      />
                    </Row>
                  )
                }
              ]}
              records={data.processExecutions.nodes}
            />
          </Box>
        )}
      </Page.Load>
    </Page.Layout>
  );
});
