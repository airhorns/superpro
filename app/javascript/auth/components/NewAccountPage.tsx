import * as React from "react";
import { RouteComponentProps } from "react-router";
import { Heading } from "grommet";
import gql from "graphql-tag";
import { NewAccountComponent, AccountAttributes, NewAccountMutationFn } from "../auth-graph";
import { PageBox } from "./PageBox";
import { Formant, SubmitBar } from "../../flurishlib/formant";
import { FormikActions, getIn } from "formik";
import { toast } from "../../flurishlib/Toast";

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

export default class NewAccountPage extends React.Component<RouteComponentProps> {
  async handleFormSubmit(createAccount: NewAccountMutationFn, values: { account: AccountAttributes }, actions: FormikActions<any>) {
    values.account.mutationClientId = "account";

    const result = await createAccount({ variables: values });
    if (result && result.data && result.data.createAccount) {
      if (result.data.createAccount.errors) {
        result.data.createAccount.errors.forEach(error => {
          if (error.mutationClientId) {
            actions.setFieldError(`${error.mutationClientId}.${error.relativeField}`, error.message);
          } else {
            actions.setFieldError("base", error.fullMessage);
          }
        });
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
    actions.setSubmitting(false);
  }

  public render() {
    const subdomainKey = "account.accountDomains[0].subdomain";
    return (
      <PageBox documentTitle="New Account">
        <Heading level="1">New Account</Heading>
        <NewAccountComponent>
          {createAccount => (
            <Formant<{ account: AccountAttributes }>
              initialValues={{ account: { name: "" } }}
              onSubmit={(values, actions) => this.handleFormSubmit(createAccount, values, actions)}
            >
              {props => (
                <>
                  <Formant.Input
                    name="account.name"
                    label="Name"
                    onChange={e => {
                      if (!getIn(props.touched, subdomainKey)) {
                        props.setFieldValue(subdomainKey, e.target.value.toLowerCase().replace(/[^A-Za-z0-9]/g, "-"));
                      }
                    }}
                  />
                  <SubmitBar />
                </>
              )}
            </Formant>
          )}
        </NewAccountComponent>
      </PageBox>
    );
  }
}
