import * as React from "react";
import { RouteComponentProps } from "react-router";
import { Heading, Button } from "grommet";
import gql from "graphql-tag";
import { NewAccountComponent, AccountAttributes, NewAccountMutationFn } from "../auth-graph";
import { PageBox } from "./PageBox";
import { toast, applyResponseErrors } from "../../flurishlib";
import { SuperForm, Input, FieldBox } from "flurishlib/superform";

gql`
  mutation NewAccount($account: AccountAttributes!) {
    createAccount(account: $account) {
      account {
        id
        name
        appUrl
      }
      errors {
        field
        relativeField
        message
        fullMessage
        mutationClientId
      }
    }
  }
`;

interface CreateAccountFormValues {
  account: AccountAttributes;
}

export default class NewAccountPage extends React.Component<RouteComponentProps> {
  async handleFormSubmit(createAccount: NewAccountMutationFn, doc: CreateAccountFormValues, form: SuperForm<CreateAccountFormValues>) {
    const variables = {
      account: {
        ...doc.account,
        mutationClientId: "account"
      }
    };

    const result = await createAccount({ variables });
    if (result && result.data && result.data.createAccount) {
      if (result.data.createAccount.errors) {
        applyResponseErrors(result.data.createAccount.errors, form);
        toast.error("Unable to save this account. Please correct the error below and try again.");
      } else {
        if (!result.data.createAccount.account) {
          throw new Error("no account returned from create call");
        }
        toast.success("Account created successfully!");
        window.location.href = result.data.createAccount.account.appUrl;
      }
    } else {
      throw new Error("no account returned from create call");
    }
  }

  public render() {
    return (
      <PageBox documentTitle="New Account">
        <Heading level="1">New Account</Heading>
        <NewAccountComponent>
          {createAccount => (
            <SuperForm<CreateAccountFormValues>
              initialValues={{ account: { name: "" } }}
              onSubmit={(doc, form) => this.handleFormSubmit(createAccount, doc, form)}
            >
              {_form => (
                <>
                  <FieldBox label="Name" path="account.name">
                    <Input path="account.name" />
                  </FieldBox>
                  <Button
                    type="submit"
                    primary
                    label="Create New Account"
                    margin={{ top: "medium" }}
                    data-test-id="create-account-submit"
                  />
                </>
              )}
            </SuperForm>
          )}
        </NewAccountComponent>
      </PageBox>
    );
  }
}
