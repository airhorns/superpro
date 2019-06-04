import React from "react";
import _ from "lodash";
import { ResponsiveContext, Layer, Box, Button, ButtonProps, Text, DropButton, Heading, Stack } from "grommet";
import { Home, FormClose } from "grommet-icons";
import { withRouter, RouteComponentProps, matchPath } from "react-router-dom";
import gql from "graphql-tag";
import { SiderInfoComponent } from "../../app-graph";
import { UserAvatar } from "../common/UserAvatar";
import { signOut } from "../../lib/auth";
import { Settings } from "../../lib/settings";
import { Row } from "../../../flurishlib";

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
    };
  } else {
    pathMatch = false;
    onClick = undefined;
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

export interface AppSidebarProps extends RouteComponentProps<{}> {
  onToggleSidebar?: () => void;
}

export const AppSidebar = withRouter(
  class InnerSidebar extends React.Component<AppSidebarProps> {
    static contextType = ResponsiveContext;

    renderMenu() {
      return (
        <SiderInfoComponent>
          {({ loading, error, data }) => {
            if (error) return `Error: ${error && error.message}`;
            if (!data) return "No data";
            return (
              <>
                <Box pad="small">
                  <Stack anchor="top-right">
                    <Heading level="2" margin="none">
                      Flurish
                    </Heading>
                    <Box round="xsmall" background="accent-2" pad={{ horizontal: "xsmall" }}>
                      <Text size="xsmall" color="white">
                        ALPHA
                      </Text>
                    </Box>
                  </Stack>
                </Box>
                {Settings.devMode && (
                  <Box background="accent-3" pad="xsmall" align="center">
                    <Text size="xxsmall">Dev Env</Text>
                  </Box>
                )}
                <AppSidebarButton path="/" exact text="Home" icon={<Home />} />
                <Box flex />
                {!loading && (
                  <Box pad="small" align="center">
                    <DropButton
                      hoverIndicator="light-4"
                      dropAlign={{ bottom: "top" }}
                      dropContent={
                        <Box pad="small" background="white" gap="small" width="small">
                          <Button onClick={() => (window.location.href = data.currentUser.authAreaUrl)}>My Apps</Button>
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
          <Layer full={true}>
            <Box align="end">
              <Button icon={<FormClose />} onClick={this.props.onToggleSidebar} />
            </Box>
            {this.renderMenu()}
          </Layer>
        );
      } else {
        return (
          <Box fill="vertical" width="small" background="light-2" elevation="xsmall">
            {this.renderMenu()}
          </Box>
        );
      }
    }
  }
);
