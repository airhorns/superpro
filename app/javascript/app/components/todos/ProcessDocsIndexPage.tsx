import React from "react";
import { Box, Text } from "grommet";
import { Page, UserCard, MutationTrashButton } from "../common";
import { Add } from "../common/SuperproIcons";
import gql from "graphql-tag";
import {
  GetAllProcessTemplatesComponent,
  GetAllProcessTemplatesQuery,
  DiscardProcessTemplateComponent,
  GetAllProcessTemplatesDocument
} from "app/app-graph";
import { Link, Row, LinkButton } from "superlib";
import { WaterTable } from "superlib/WaterTable";
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

type ProcessTemplate = ArrayElementType<GetAllProcessTemplatesQuery["processTemplates"]["nodes"]>;

export default () => {
  return (
    <Page.Layout title="Process Docs" headerExtra={<LinkButton icon={<Add />} label="New Process Doc" to="/todos/process/docs/new" />}>
      <Page.Load component={GetAllProcessTemplatesComponent}>
        {data => (
          <Box>
            <WaterTable<ProcessTemplate>
              columns={[
                {
                  header: "Name",
                  key: "name",
                  render: processTemplate => <Link to={`/todos/process/docs/${processTemplate.id}`}>{processTemplate.name}</Link>
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
                          <Link to={`/todos/process/runs/${processTemplate.lastExecution.id}`}>
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
                      <LinkButton to={`/todos/process/docs/${processTemplate.id}/start`} label="Run Now" />
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
};
