import React from "react";
import { Page } from "../common";
import { Box } from "grommet";
import useReactRouter from "use-react-router";
import { Spin, mutationSuccess, toast } from "superlib";
import { useCreateNewProcessTemplateMutation } from "app/app-graph";
import gql from "graphql-tag";

gql`
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
`;

export default () => {
  const create = useCreateNewProcessTemplateMutation();
  const { history } = useReactRouter();

  React.useEffect(() => {
    (async () => {
      let success = false;
      let result;
      try {
        result = await create();
      } catch (e) {}

      const data = mutationSuccess(result, "createProcessTemplate");
      if (data) {
        success = true;
        history.replace(`/todos/process/docs/${data.processTemplate.id}`);
      }

      if (!success) {
        toast.error("There was an error creating a process doc. Please try again.");
      }
    })();
  });

  return (
    <Page.Layout title="New Process Doc">
      <Box align="center">
        <Spin />
      </Box>
    </Page.Layout>
  );
};
