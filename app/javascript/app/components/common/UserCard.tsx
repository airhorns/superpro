import React from "react";
import gql from "graphql-tag";
import { Text } from "grommet";
import { UserAvatar } from "./UserAvatar";
import { Row, Link } from "superlib";

gql`
  fragment UserCard on User {
    id
    email
    fullName
  }
`;

export interface UserCardProps {
  user: { email: string; fullName: string; id: string };
  link?: boolean;
}

export const UserCard = (props: UserCardProps) => (
  <Row gap="small">
    <UserAvatar user={props.user} size={32} />
    {props.link ? <Link to={`/users/${props.user.id}`}>{props.user.fullName}</Link> : <Text>{props.user.fullName}</Text>}
  </Row>
);
