import React from "react";
import { isUndefined } from "lodash";
import { RouteComponentProps, withRouter, matchPath } from "react-router";
import { ButtonProps, Button, Text, Box } from "grommet";
import { Row } from "flurishlib";

interface NavigationSectionButtonProps extends RouteComponentProps<{}> {
  onClick?: (e: React.SyntheticEvent) => void;
  icon?: ButtonProps["icon"];
  text: string;
  path?: string;
  children?: React.ReactNode;
}

export const navigate = (history: RouteComponentProps["history"], path: string) => {
  // toast.removeAll(); waiting on https://github.com/jossmac/react-toast-notifications/pull/37
  if (path && path.startsWith("http")) {
    window.location.href = path;
  } else {
    history.push(path);
  }
};

export const NavigationSectionButton = withRouter((props: NavigationSectionButtonProps) => {
  let pathMatch, onClick;
  // If this section has children, prefix match on the route, otherwise, exact match it.
  const exact = isUndefined(props.children);

  if (!isUndefined(props.path)) {
    pathMatch = !!matchPath(props.location.pathname, { exact: exact, path: props.path });
    onClick = (e: React.MouseEvent) => {
      e.preventDefault();
      navigate(props.history, props.path as any);
      props.onClick && props.onClick(e);
    };
  } else {
    pathMatch = false;
    onClick = props.onClick;
  }

  return (
    <>
      <Button hoverIndicator="light-4" active={pathMatch} onClick={onClick} as="a" href={props.path}>
        <Row pad="small" gap="small">
          {props.icon && <Text>{props.icon}</Text>}
          <Text>{props.text}</Text>
        </Row>
      </Button>
      {props.children && pathMatch && (
        <Box margin={{ bottom: "small" }} background={pathMatch ? "light-3" : undefined}>
          {props.children}
        </Box>
      )}
    </>
  );
});

interface NavigationSubItemButtonProps extends RouteComponentProps<{}> {
  onClick?: (e: React.SyntheticEvent) => void;
  icon?: ButtonProps["icon"];
  text: string;
  path?: string;
  exact?: boolean;
}

export const NavigationSubItemButton = withRouter((props: NavigationSubItemButtonProps) => {
  let pathMatch, onClick;

  if (!isUndefined(props.path)) {
    pathMatch = !!matchPath(props.location.pathname, { exact: props.exact, path: props.path });
    onClick = (e: React.MouseEvent) => {
      e.preventDefault();
      navigate(props.history, props.path as any);
      props.onClick && props.onClick(e);
    };
  } else {
    pathMatch = false;
    onClick = props.onClick;
  }

  const weight = pathMatch ? "bold" : "normal";
  return (
    <Button hoverIndicator="light-4" onClick={onClick} as="a" href={props.path}>
      <Row pad={{ left: "medium", vertical: "xsmall" }} gap="small">
        {props.icon && <Text weight={weight}>{props.icon}</Text>}
        <Text weight={weight}>{props.text}</Text>
      </Row>
    </Button>
  );
});
