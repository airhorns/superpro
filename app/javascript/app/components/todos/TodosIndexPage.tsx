import React from "react";
import gql from "graphql-tag";
import { Page } from "../common";
import { GetMyTodosComponent } from "app/app-graph";
import { Box } from "grommet";
import { CondensedProcessExecutionForm } from "./CondensedProcessExecutionForm";
import { Scratchpad } from "./Scratchpad";

gql`
  query GetMyTodos {
    currentUser {
      id
      involvedProcessExecutions {
        nodes {
          id
          name
          ...CondensedProcessExecutionForm
        }
      }
    }
    ...ContextForProcessEditor
  }
`;

export default (_props: {}) => {
  return (
    <Page.Layout title="My Todos" padded={false}>
      <Page.Load component={GetMyTodosComponent}>
        {data => (
          <Box flex background="light-1">
            <Scratchpad />
            {data.currentUser.involvedProcessExecutions.nodes.map(processExecution => (
              <Box key={processExecution.id}>
                <CondensedProcessExecutionForm processExecution={processExecution} users={data.users.nodes} />
              </Box>
            ))}
          </Box>
        )}
      </Page.Load>
    </Page.Layout>
  );
};
