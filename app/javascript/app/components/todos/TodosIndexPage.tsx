import React from "react";
import gql from "graphql-tag";
import { Text, Grid } from "grommet";
import InfiniteScroll from "react-infinite-scroll-component";
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
import { Add } from "../common/SuperproIcons";
import { mutationSuccess, toast, SimpleQuery, Spin, RelayConnectionQueryUpdater, assert } from "superlib";
import { DateTime } from "luxon";
import { UserAvatarList } from "../common/UserAvatarList";

gql`
  query GetMyTodos($after: String) {
    currentUser {
      id
      todoFeedItems(first: 30, after: $after) {
        pageInfo {
          endCursor
          hasNextPage
        }
        edges {
          node {
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
      scrolly={false}
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
          indexData.currentUser.todoFeedItems.edges.length > 0 &&
          !selectedItem &&
          setSelectedItem(assert(indexData.currentUser.todoFeedItems.edges[0].node).todoSource)
        }
      >
        {(indexData, result) => (
          <Grid
            fill
            rows={["flex"]}
            columns={["small", "flex"]}
            areas={[{ name: "feed", start: [0, 0], end: [0, 0] }, { name: "editor", start: [1, 0], end: [1, 0] }]}
          >
            <Box gridArea="feed" border={{ side: "right", color: "light-3" }}>
              <Box overflow={{ vertical: "auto" }} id="todo-feed-infinite-scroll">
                <InfiniteScroll
                  dataLength={indexData.currentUser.todoFeedItems.edges.length}
                  scrollableTarget="todo-feed-infinite-scroll"
                  next={() =>
                    result.fetchMore({
                      variables: { after: indexData.currentUser.todoFeedItems.pageInfo.endCursor },
                      updateQuery: RelayConnectionQueryUpdater("currentUser.todoFeedItems")
                    })
                  }
                  hasMore={indexData.currentUser.todoFeedItems.pageInfo.hasNextPage}
                  loader={
                    <Box align="center">
                      <Spin />
                    </Box>
                  }
                  endMessage={
                    <Box align="center" pad="xsmall">
                      <Text color="status-unknown">No more todos.</Text>
                    </Box>
                  }
                >
                  {indexData.currentUser.todoFeedItems.edges.map(edge => {
                    const feedItem = assert(edge.node);
                    return (
                      <Box
                        key={feedItem.id}
                        background={{
                          color:
                            selectedItem &&
                            feedItem.todoSource.__typename == selectedItem.__typename &&
                            feedItem.todoSource.id == selectedItem.id
                              ? "white"
                              : "light-1"
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
                    );
                  })}
                </InfiniteScroll>
              </Box>
            </Box>
            <Box gridArea="editor" background="light-1">
              <Box overflow={{ vertical: "auto" }}>
                {selectedItem && selectedItem.__typename == "ProcessExecution" && (
                  <SimpleQuery
                    component={GetProcessExecutionForTodosComponent}
                    require={["processExecution"]}
                    variables={{ id: selectedItem.id }}
                  >
                    {data => (
                      <CondensedProcessExecutionForm
                        key={data.processExecution.id}
                        processExecution={data.processExecution}
                        users={indexData.users.nodes}
                      />
                    )}
                  </SimpleQuery>
                )}
                {selectedItem && selectedItem.__typename == "Scratchpad" && (
                  <SimpleQuery component={GetScratchpadForTodosComponent} require={["scratchpad"]} variables={{ id: selectedItem.id }}>
                    {data => <ScratchpadForm key={data.scratchpad.id} scratchpad={data.scratchpad} users={indexData.users.nodes} />}
                  </SimpleQuery>
                )}
              </Box>
            </Box>
          </Grid>
        )}
      </Page.Load>
    </Page.Layout>
  );
};
