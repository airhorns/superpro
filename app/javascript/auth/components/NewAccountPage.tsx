import * as React from "react";
import { RouteComponentProps } from "react-router";
import { Heading } from "grommet";
import gql from "graphql-tag";
import { PageBox } from "./PageBox";

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
  public render() {
    return (
      <PageBox documentTitle="New Account">
        <Heading level="1">New Account</Heading>
      </PageBox>
    );
  }
}
