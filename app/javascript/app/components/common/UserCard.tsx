import React from "react";
import gql from "graphql-tag";
import { Text } from "grommet";
import { UserAvatar } from "./UserAvatar";
import { Row, Link } from "superlib";

gql`
  fragment UserCard on User {
    id
    email
    primaryTextIdentifier
  }
`;

export interface UserCardProps {
  user: { email: string; primaryTextIdentifier: string; id: string };
  link?: boolean;
}

export const UserCard = (props: UserCardProps) => (
  <Row gap="small">
    <UserAvatar user={props.user} size={32} />
    {props.link ? (
      <Link to={`/users/${props.user.id}`}>{props.user.primaryTextIdentifier}</Link>
    ) : (
      <Text>{props.user.primaryTextIdentifier}</Text>
    )}
  </Row>
);
