import React from "react";
import { Row } from "superlib";
import { UserAvatar, UserAvatarProps } from "./UserAvatar";

export const UserAvatarList = (props: { users: UserAvatarProps["user"][]; size?: UserAvatarProps["size"] }) => {
  return (
    <Row>
      {props.users.map(user => (
        <UserAvatar key={user.id} user={user} size={props.size} />
      ))}
    </Row>
  );
};
