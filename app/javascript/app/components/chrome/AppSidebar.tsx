import React from "react";
import { ResponsiveContext, Layer, Box, Button, Text, DropButton, Heading } from "grommet";
import { FormClose, Menu, Launch } from "grommet-icons";
import { withRouter, RouteComponentProps } from "react-router-dom";
import gql from "graphql-tag";
import { SiderInfoComponent } from "../../app-graph";
import { UserAvatar } from "../common/UserAvatar";
import { signOut } from "../../lib/auth";
import { Settings } from "../../lib/settings";
import { Row } from "../../../flurishlib";
import { Budget, Tasks } from "../common/FlurishIcons";
import { NavigationSectionButton, NavigationSubItemButton } from "./Navigation";

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

                <NavigationSectionButton path="/" text="Launchpad" icon={<Launch />} onClick={this.close} />
                <NavigationSectionButton path="/budget" text="Budgets" icon={<Budget />} onClick={this.close}>
                  <NavigationSubItemButton path="/budget" exact text="My Budget" onClick={this.close} />
                  <NavigationSubItemButton path="/budget/reports" text="Reports" onClick={this.close} />
                </NavigationSectionButton>
                <NavigationSectionButton path="/" text="Tasks" icon={<Tasks />} onClick={this.close} />
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
