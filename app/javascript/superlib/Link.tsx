import React from "react";
import { Anchor, AnchorProps, Button, ButtonProps } from "grommet";
import { withRouter, RouteComponentProps } from "react-router";

export interface LinkProps {
  to: string;
}

export const Link = withRouter((props: AnchorProps & LinkProps & RouteComponentProps) => (
  <Anchor
    {...props}
    onClick={() => {
      props.history.push(props.to);
    }}
  />
));

export const LinkButton = withRouter((props: ButtonProps & LinkProps & RouteComponentProps) => (
  <Button
    {...props}
    onClick={() => {
      props.history.push(props.to);
    }}
  />
));
