import React from "react";
import { RouteComponentProps } from "react-router";

import { Box, Paragraph, Button } from "grommet";
import gql from "graphql-tag";
import { GetGoogleAnalyticsViewsComponent, useCompleteGoogleAnalyticsSetupMutation, GetConnectionsIndexPageDocument } from "app/app-graph";
import { Page } from "../../common";
import { SuperForm, Select } from "superlib/superform";
import { mutationSuccess, toast } from "superlib";
import { returnToOrigin } from "./utils";

gql`
  query GetGoogleAnalyticsViews($credentialId: ID!) {
    googleAnalyticsViews(credentialId: $credentialId) {
      nodes {
        name
        id
        propertyName
        propertyId
        accountName
        accountId
        alreadySetup
      }
    }
  }

  mutation CompleteGoogleAnalyticsSetup($credentialId: ID!, $viewId: String!) {
    completeGoogleAnalyticsSetup(credentialId: $credentialId, viewId: $viewId) {
      googleAnalyticsCredential {
        id
      }
    }
  }
`;

const optionsForViews = (viewNodes: { id: string; name: string; propertyName: string; accountName: string; alreadySetup: boolean }[]) =>
  viewNodes.map(node => ({
    value: node.id,
    label: (
      <>
        {node.accountName} - {node.propertyName} - {node.name} ({node.id})
      </>
    ),
    isDisabled: node.alreadySetup
  }));

interface CompleteGoogleAnalyticsSetupFormValues {
  viewId: string;
}

export default (props: RouteComponentProps<{ credentialId: string }>) => {
  const completeSetup = useCompleteGoogleAnalyticsSetupMutation();
  const onSubmit = React.useCallback(
    async (form: CompleteGoogleAnalyticsSetupFormValues) => {
      let result;
      try {
        result = await completeSetup({
          variables: { credentialId: props.match.params.credentialId, viewId: form.viewId },
          refetchQueries: [{ query: GetConnectionsIndexPageDocument }]
        });
      } catch (e) {}

      const data = mutationSuccess(result, "completeGoogleAnalyticsSetup");
      if (data) {
        toast.success("Google Analytics set up successfully!");
        returnToOrigin(props);
      } else {
        toast.error("Google Analytics failed to set up. Please try again.");
      }
    },
    [completeSetup, props]
  );

  return (
    <Page.TakeoverLayout title="Complete Google Analytics Connection Setup">
      <Page.Load
        component={GetGoogleAnalyticsViewsComponent}
        require={["googleAnalyticsViews"]}
        variables={{ credentialId: props.match.params.credentialId }}
      >
        {data => (
          <SuperForm<CompleteGoogleAnalyticsSetupFormValues> initialValues={{ viewId: "" }} onSubmit={onSubmit}>
            {() => (
              <Box gap="small" width="medium" alignSelf="center">
                <Paragraph>
                  To complete the setup of this Google Analytics data, please select from your available Google Analytics profiles:
                </Paragraph>
                <Select path="viewId" options={optionsForViews(data.googleAnalyticsViews.nodes)} />
                <Button primary label="Complete Set Up" type="submit" />
              </Box>
            )}
          </SuperForm>
        )}
      </Page.Load>
    </Page.TakeoverLayout>
  );
};
