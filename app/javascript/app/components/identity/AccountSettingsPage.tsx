import React from "react";
import gql from "graphql-tag";
import { Page } from "../common";
import { GetAccountForSettingsComponent, useUpdateAccountSettingsMutation } from "app/app-graph";
import { SuperForm, Input, FieldBox } from "superlib/superform";
import { Box, Button } from "grommet";
import { Row, mutationSuccess, toast } from "superlib";

gql`
  query GetAccountForSettings {
    account: currentAccount {
      id
      name
    }
  }

  mutation UpdateAccountSettings($attributes: AccountAttributes!) {
    updateAccount(attributes: $attributes) {
      account {
        id
        name
      }
      errors {
        fullMessage
      }
    }
  }
`;

interface AccountSettingsFormValues {
  account: {
    name: string;
  };
}

export default (_props: {}) => {
  const updateAccountSettings = useUpdateAccountSettingsMutation();
  const handleSubmit = React.useCallback(
    async (formValues: AccountSettingsFormValues) => {
      let success = false;
      let result;
      try {
        result = await updateAccountSettings({
          variables: {
            attributes: formValues.account
          }
        });
      } catch (e) {}

      const data = mutationSuccess(result, "updateAccount");
      if (data) {
        success = true;
        toast.success("Account settings updated successfully.");
      }

      if (!success) {
        toast.error("There was an error updating this account. Please try again.");
      }
    },
    [updateAccountSettings]
  );

  return (
    <Page.Layout title="Account Settings">
      <Page.Load component={GetAccountForSettingsComponent} require={["account"]}>
        {data => (
          <SuperForm<AccountSettingsFormValues> initialValues={{ account: { name: data.account.name } }} onSubmit={handleSubmit}>
            {() => (
              <Box gap="small">
                <FieldBox path="account.name" label="Account Name">
                  <Input path="account.name" />
                </FieldBox>
                <Row>
                  <Button type="submit" label="Save Account" />
                </Row>
              </Box>
            )}
          </SuperForm>
        )}
      </Page.Load>
    </Page.Layout>
  );
};
