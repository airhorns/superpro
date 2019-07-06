import React from "react";
import gql from "graphql-tag";
import { Text } from "grommet";
import { Page } from "../common";
import {
  GetMyTodosComponent,
  GetMyTodosDocument,
  useCreateNewScratchpadMutation,
  GetScratchpadForTodosComponent,
  GetProcessExecutionForTodosComponent
} from "app/app-graph";
import { Box, Button } from "grommet";
import { CondensedProcessExecutionForm } from "./CondensedProcessExecutionForm";
import { ScratchpadForm } from "./ScratchpadForm";
import { Add } from "../common/FlurishIcons";
import { mutationSuccess, toast, SimpleQuery } from "flurishlib";
import { DateTime } from "luxon";
import { UserAvatarList } from "../common/UserAvatarList";

gql`
  query GetMyTodos {
    currentUser {
      id
      todoFeedItems {
        nodes {
          id
          updatedAt
          todoSource {
            __typename
            ... on ProcessExecution {
              id
              name
              involvedUsers {
                ...UserCard
              }
            }
            ... on Scratchpad {
              id
              name
            }
          }
        }
      }
    }
    ...ContextForTodoEditor
  }

  query GetProcessExecutionForTodos($id: ID!) {
    processExecution(id: $id) {
      name
      ...CondensedProcessExecutionForm
    }
  }

  query GetScratchpadForTodos($id: ID!) {
    scratchpad(id: $id) {
      id
      ...ScratchpadForm
    }
  }

  mutation CreateNewScratchpad {
    createScratchpad {
      scratchpad {
        id
        ...ScratchpadForm
      }
      errors {
        fullMessage
      }
    }
  }
`;

type SelectedFeedItem = null | { __typename: "ProcessExecution" | "Scratchpad"; id: string };

export default (_props: {}) => {
  const [selectedItem, setSelectedItem] = React.useState<SelectedFeedItem>(null);
  const createScratchpad = useCreateNewScratchpadMutation({ refetchQueries: [{ query: GetMyTodosDocument }] });

  return (
    <Page.Layout
      title="My Todos"
      padded={false}
      headerExtra={
        <Button
          icon={<Add />}
          label="Create Scratchpad"
          onClick={async () => {
            let success = false;
            let result;
            try {
              result = await createScratchpad();
            } catch (e) {}

            const data = mutationSuccess(result, "createScratchpad");
            if (data) {
              success = true;
            }

            if (!success) {
              toast.error("There was an error creating a scratchpad. Please try again.");
            }
          }}
        />
      }
    >
      <Page.Load
        component={GetMyTodosComponent}
        onCompleted={indexData =>
          indexData.currentUser.todoFeedItems.nodes.length > 0 && setSelectedItem(indexData.currentUser.todoFeedItems.nodes[0].todoSource)
        }
      >
        {indexData => (
          <Box direction="row" flex background="light-1">
            <Box width="small" border={{ side: "right", color: "light-3" }}>
              {indexData.currentUser.todoFeedItems.nodes.map(feedItem => (
                <Box
                  key={feedItem.id}
                  background={{
                    color:
                      selectedItem && feedItem.todoSource.__typename == selectedItem.__typename && feedItem.todoSource.id == selectedItem.id
                        ? "white"
                        : undefined
                  }}
                >
                  <Button
                    onClick={() => setSelectedItem({ __typename: feedItem.todoSource.__typename, id: feedItem.todoSource.id })}
                    hoverIndicator
                  >
                    <Box pad="small" border={{ side: "bottom", color: "light-3" }}>
                      <Text>{feedItem.todoSource.name}</Text>
                      <Text size="small">{DateTime.fromISO(feedItem.updatedAt).toLocaleString(DateTime.DATETIME_MED)}</Text>
                      {feedItem.todoSource.__typename == "ProcessExecution" && (
                        <UserAvatarList users={feedItem.todoSource.involvedUsers} size={32} />
                      )}
                    </Box>
                  </Button>
                </Box>
              ))}
            </Box>
            <Box flex background="light-1">
              {selectedItem && selectedItem.__typename == "ProcessExecution" && (
                <SimpleQuery
                  component={GetProcessExecutionForTodosComponent}
                  require={["processExecution"]}
                  variables={{ id: selectedItem.id }}
                >
                  {data => <CondensedProcessExecutionForm processExecution={data.processExecution} users={indexData.users.nodes} />}
                </SimpleQuery>
              )}
              {selectedItem && selectedItem.__typename == "Scratchpad" && (
                <SimpleQuery component={GetScratchpadForTodosComponent} require={["scratchpad"]} variables={{ id: selectedItem.id }}>
                  {data => <ScratchpadForm scratchpad={data.scratchpad} users={indexData.users.nodes} />}
                </SimpleQuery>
              )}
            </Box>
          </Box>
        )}
      </Page.Load>
    </Page.Layout>
  );
};
