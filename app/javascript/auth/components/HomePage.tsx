import * as React from "react";
import { RouteComponentProps } from "react-router";
import { Box, Heading, Anchor, Paragraph, Button, Menu } from "grommet";
import gql from "graphql-tag";
import { AllAccountsComponent, DiscardAccountComponent, AllAccountsDocument } from "../auth-graph";
import { PageBox } from "./PageBox";
import { SimpleQuery } from "../../superlib/SimpleQuery";
import { Row } from "../../superlib/Row";
import { toast, formatDate } from "../../superlib";
import { Trash, Edit } from "app/components/common/SuperproIcons";

gql`
  query AllAccounts {
    accounts {
      id
      name
      createdAt
      appUrl
      creator {
        fullName
      }
    }
  }

  mutation DiscardAccount($id: ID!) {
    discardAccount(id: $id) {
      account {
        id
        name
        discarded
      }
      errors {
        field
        message
      }
    }
  }
`;

export default class HomePage extends React.Component<RouteComponentProps> {
  public render() {
    return (
      <PageBox>
        <Row tag="header" background="white" justify="between" pad="small">
          <Heading level="1">Accounts</Heading>
          <Button onClick={() => this.props.history.push("/new_account")} label="New Account" />
        </Row>
        <SimpleQuery component={AllAccountsComponent} require={["accounts"]}>
          {data =>
            data.accounts.map(account => (
              <Box key={account.id} pad="medium">
                <Row justify="between">
                  <Heading level="3">
                    <Anchor href={account.appUrl}>{account.name}</Anchor>
                  </Heading>
                  <DiscardAccountComponent variables={{ id: account.id }} refetchQueries={[{ query: AllAccountsDocument }]}>
                    {discardAccount => (
                      <Menu
                        label={<Edit />}
                        items={[
                          {
                            label: (
                              <Row gap="small">
                                <Trash />
                                Discard
                              </Row>
                            ),
                            onClick: async () => {
                              let result;
                              try {
                                result = await discardAccount();
                              } catch (e) {
                                toast.error("There was an error discarding this account. Please try again.");
                                return;
                              }
                              if (result && result.data && result.data.discardAccount && result.data.discardAccount.account) {
                                toast.success("Account discarded.");
                              } else {
                                toast.error("There was an error discarding this account. Please try again.");
                              }
                            }
                          }
                        ]}
                      />
                    )}
                  </DiscardAccountComponent>
                </Row>
                <Paragraph>
                  Created by {account.creator.fullName} at {formatDate(account.createdAt)}
                </Paragraph>
              </Box>
            ))
          }
        </SimpleQuery>
      </PageBox>
    );
  }
}
