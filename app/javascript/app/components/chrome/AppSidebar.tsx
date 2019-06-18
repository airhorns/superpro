import React from "react";
import _ from "lodash";
import { ResponsiveContext, Layer, Box, Button, ButtonProps, Text, DropButton, Heading, Stack } from "grommet";
import { Home, FormClose, Menu } from "grommet-icons";
import { withRouter, RouteComponentProps, matchPath } from "react-router-dom";
import gql from "graphql-tag";
import { SiderInfoComponent } from "../../app-graph";
import { UserAvatar } from "../common/UserAvatar";
import { signOut } from "../../lib/auth";
import { Settings } from "../../lib/settings";
import { Row } from "../../../flurishlib";
import { Budget } from "../common/FlurishIcons";

gql`
  query SiderInfo {
    currentUser {
      email
      fullName
      preferences {
        sidebarExpanded
      }
      authAreaUrl
    }
  }
`;

interface AppSidebarButtonProps extends RouteComponentProps<{}> {
  onClick?: (e: React.SyntheticEvent) => void;
  icon?: ButtonProps["icon"];
  text: string;
  path?: string;
  exact?: boolean;
}

const AppSidebarButton = withRouter((props: AppSidebarButtonProps) => {
  let pathMatch, onClick;
  if (!_.isUndefined(props.path)) {
    pathMatch = !!matchPath(props.location.pathname, { exact: props.exact, path: props.path });
    onClick = (e: React.MouseEvent) => {
      // toast.removeAll(); waiting on https://github.com/jossmac/react-toast-notifications/pull/37
      if (props.path && props.path.startsWith("http")) {
        window.location.href = props.path;
      } else {
        props.history.push(props.path as any);
      }
      e.preventDefault();
      props.onClick && props.onClick(e);
    };
  } else {
    pathMatch = false;
    onClick = props.onClick;
  }

  return (
    <Button hoverIndicator="light-4" active={pathMatch} onClick={onClick} as="a" href={props.path}>
      <Row pad="small" gap="small">
        {props.icon && <Text>{props.icon}</Text>}
        <Text>{props.text}</Text>
      </Row>
    </Button>
  );
});

interface AppSidebarState {
  openForSmall: boolean;
}

export const AppSidebar = withRouter(
  class InnerSidebar extends React.Component<RouteComponentProps<{}>, AppSidebarState> {
    static contextType = ResponsiveContext;
    state: AppSidebarState = { openForSmall: false };

    close = () => {
      this.setState({ openForSmall: false });
    };

    renderLogo() {
      return (
        <Box flex={false}>
          <Heading level="2">Flurish</Heading>
        </Box>
      );
    }
    renderMenu() {
      return (
        <SiderInfoComponent>
          {({ loading, error, data }) => {
            if (error) return `Error: ${error && error.message}`;
            if (!data) return "No data";
            return (
              <>
                <Box pad="small" align="center">
                  {this.renderLogo()}
                </Box>
                <Box background="accent-2" align="center">
                  <Text size="xsmall" color="white">
                    ALPHA
                  </Text>
                </Box>
                {Settings.devMode && (
                  <Box background="accent-3" align="center">
                    <Text size="xsmall" color="white">
                      DEV ENV
                    </Text>
                  </Box>
                )}

                <AppSidebarButton path="/" exact text="Home" icon={<Home />} onClick={this.close} />
                <AppSidebarButton path="/budget" exact text="Budget" icon={<Budget />} onClick={this.close} />
                <Box flex />
                {!loading && (
                  <Box pad="small" align="center">
                    <DropButton
                      hoverIndicator="light-4"
                      dropAlign={{ bottom: "top" }}
                      dropContent={
                        <Box pad="small" background="white" gap="small" width="small">
                          <Button onClick={() => (window.location.href = data.currentUser.authAreaUrl)}>Switch Accounts</Button>
                          <Button onClick={signOut}>Sign Out</Button>
                        </Box>
                      }
                    >
                      <UserAvatar user={data.currentUser} size={48} />
                    </DropButton>
                  </Box>
                )}
              </>
            );
          }}
        </SiderInfoComponent>
      );
    }

    render() {
      const size = this.context;

      if (size === "small") {
        return (
          <>
            <Row justify="center">
              <Box flex>
                <Button
                  icon={<Menu />}
                  onClick={() => {
                    this.setState({ openForSmall: true });
                  }}
                />
              </Box>
              <Box flex={false}>{this.renderLogo()}</Box>
              <Box flex />
            </Row>
            {this.state.openForSmall && (
              <Layer full={true}>
                <Button icon={<FormClose />} onClick={this.close} style={{ position: "fixed", top: 0, right: 0 }} />
                {this.renderMenu()}
              </Layer>
            )}
          </>
        );
      } else {
        return (
          <Box fill="vertical" width="small" background="light-2">
            {this.renderMenu()}
          </Box>
        );
      }
    }
  }
);
