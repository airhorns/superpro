import React from "react";
import { RouteComponentProps } from "react-router";
import { Box, Paragraph, Button } from "grommet";
import gql from "graphql-tag";
import { GetFacebookAdAccountsComponent, useCompleteFacebookAdAccountSetupMutation, GetConnectionsIndexPageDocument } from "app/app-graph";
import { Page } from "../../common";
import { SuperForm, Select } from "superlib/superform";
import { mutationSuccess, toast } from "superlib";
import { returnToOrigin } from "./utils";

gql`
  query GetFacebookAdAccounts($facebookAdAccountId: ID!) {
    availableFacebookAdAccounts(facebookAdAccountId: $facebookAdAccountId) {
      nodes {
        id
        name
        currency
        age
        alreadySetup
      }
    }
  }

  mutation CompleteFacebookAdAccountSetup($facebookAdAccountId: ID!, $selectedFbAccountId: String!) {
    completeFacebookAdAccountSetup(facebookAdAccountId: $facebookAdAccountId, selectedFbAccountId: $selectedFbAccountId) {
      facebookAdAccount {
        id
      }
    }
  }
`;

const optionsForViews = (viewNodes: { id: string; name: string; currency: string; age: string; alreadySetup: boolean }[]) =>
  viewNodes.map(node => ({
    value: node.id,
    label: (
      <>
        {node.name} - {node.currency} ({node.age} days old, ID {node.id})
      </>
    ),
    isDisabled: node.alreadySetup
  }));

interface CompleteGoogleAnalyticsSetupFormValues {
  accountId: string;
}

export default (props: RouteComponentProps<{ facebookAdAccountId: string }>) => {
  const completeSetup = useCompleteFacebookAdAccountSetupMutation();
  const onSubmit = React.useCallback(
    async (form: CompleteGoogleAnalyticsSetupFormValues) => {
      let result;
      try {
        result = await completeSetup({
          variables: { facebookAdAccountId: props.match.params.facebookAdAccountId, selectedFbAccountId: form.accountId },
          refetchQueries: [{ query: GetConnectionsIndexPageDocument }]
        });
      } catch (e) {}

      const data = mutationSuccess(result, "completeFacebookAdAccountSetup");
      if (data) {
        toast.success("Facebook set up successfully!");
        returnToOrigin(props);
      } else {
        toast.error("Facebook failed to set up. Please try again.");
      }
    },
    [completeSetup, props]
  );

  return (
    <Page.TakeoverLayout title="Complete Facebook Connection Setup">
      <Page.Load
        component={GetFacebookAdAccountsComponent}
        require={["availableFacebookAdAccounts"]}
        variables={{ facebookAdAccountId: props.match.params.facebookAdAccountId }}
      >
        {data => (
          <SuperForm<CompleteGoogleAnalyticsSetupFormValues> initialValues={{ accountId: "" }} onSubmit={onSubmit}>
            {() => (
              <Box gap="small" width="medium" alignSelf="center">
                <Paragraph>To complete the setup of this Facebook data, please select from your available Facebook Ad Accounts:</Paragraph>
                <Select path="accountId" options={optionsForViews(data.availableFacebookAdAccounts.nodes)} />
                <Button primary label="Complete Set Up" type="submit" />
              </Box>
            )}
          </SuperForm>
        )}
      </Page.Load>
    </Page.TakeoverLayout>
  );
};
