import React from "react";
import Gravatar from "react-gravatar";
import "./user-avatar.scss";

export interface UserAvatarProps {
  user: { id: string; email: string; primaryTextIdentifier: string };
  size?: number;
}

export class UserAvatar extends React.Component<UserAvatarProps> {
  static defaultProps = {
    size: 48
  };

  render() {
    return (
      <Gravatar
        className="user-avatar"
        protocol={"https://"}
        email={this.props.user.email}
        size={this.props.size}
        default={`https://ui-avatars.com/api/${encodeURIComponent(this.props.user.primaryTextIdentifier)}/${this.props.size}` as any}
      />
    );
  }
}
