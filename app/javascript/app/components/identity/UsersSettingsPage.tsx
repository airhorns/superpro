import React from "react";
import gql from "graphql-tag";
import { Page, LinkButton, UserAvatar } from "../common";
import { Text, Box } from "grommet";
import { GetUsersForSettingsComponent } from "app/app-graph";
import { Row } from "superlib";

gql`
  query GetUsersForSettings {
    users {
      nodes {
        id
        fullName
        email
        pendingInvitation
        ...UserCard
      }
    }
  }
`;

interface User {
  id: string;
  email: string;
  fullName?: string | null;
  primaryTextIdentifier: string;
  pendingInvitation: boolean;
}

const UserRow = (props: { user: User }) => {
  let primaryText: string;
  let secondaryText: string | undefined = undefined;

  if (props.user.fullName) {
    primaryText = props.user.fullName;
    secondaryText = props.user.email;
  } else {
    primaryText = props.user.email;
    secondaryText = "Not yet configured";
  }

  return (
    <Row pad="small" justify="between">
      <Row gap="small">
        <UserAvatar user={props.user} size={32} />
        <Box>
          <Text>{primaryText}</Text>
          <Text size="small" color="dark-2">
            {secondaryText}
          </Text>
        </Box>
      </Row>
      {props.user.pendingInvitation && <Text color="status-unknown">Invitation pending</Text>}
    </Row>
  );
};
export default (_props: {}) => {
  return (
    <Page.Layout title="Users Settings" headerExtra={<LinkButton primary to="/invite" label="Invite New Users" />}>
      <Page.Load component={GetUsersForSettingsComponent} require={["users"]}>
        {data => (
          <Box>
            {data.users.nodes.map(user => (
              <UserRow key={user.id} user={user} />
            ))}
          </Box>
        )}
      </Page.Load>
    </Page.Layout>
  );
};
