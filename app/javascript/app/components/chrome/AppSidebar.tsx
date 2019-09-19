import React from "react";
import { ResponsiveContext, Layer, Box, Button, Text, DropButton, Heading } from "grommet";
import { FormClose, Menu, Launch } from "grommet-icons";
import { withRouter, RouteComponentProps } from "react-router-dom";
import gql from "graphql-tag";
import { SiderInfoComponent } from "../../app-graph";
import { UserAvatar } from "../common/UserAvatar";
import { signOut } from "../../lib/auth";
import { Settings } from "../../lib/settings";
// import { Flag } from "../../../superlib";
import { Invite, Settings as SettingsIcon } from "../common/SuperproIcons";
import { NavigationSectionButton, NavigationSubItemButton } from "./Navigation";

gql`
  query SiderInfo {
    currentUser {
      email
      fullName
      authAreaUrl
      ...UserCard
    }
  }
`;

interface AppSidebarState {
  openForSmall: boolean;
}

export const AppSidebar = withRouter(
  class InnerSidebar extends React.Component<RouteComponentProps & { embeddedInPageHeader: boolean }, AppSidebarState> {
    static contextType = ResponsiveContext;
    state: AppSidebarState = { openForSmall: false };

    close = () => {
      this.setState({ openForSmall: false });
    };

    renderLogo() {
      return (
        <Box flex={false}>
          <Heading level="2">Superpro</Heading>
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
                <Box pad="small" align="center" flex={false}>
                  {this.renderLogo()}
                </Box>
                <Box background="accent-2" align="center" flex={false}>
                  <Text size="xsmall" color="white">
                    ALPHA
                  </Text>
                </Box>
                {Settings.devMode && (
                  <Box background="accent-3" align="center" flex={false}>
                    <Text size="xsmall" color="white">
                      DEV ENV
                    </Text>
                  </Box>
                )}
                <Box flex="grow" overflow={{ vertical: "auto" }}>
                  <NavigationSectionButton path="/launchpad" text="Launchpad" icon={<Launch />} onClick={this.close} />
                  <Box flex />
                  <NavigationSectionButton path="/invite" text="Invite Users" icon={<Invite />} onClick={this.close} />
                  <NavigationSectionButton path="/settings" text="Settings" icon={<SettingsIcon />} onClick={this.close}>
                    <NavigationSubItemButton path="/settings/account" exact text="Account" onClick={this.close} />
                    <NavigationSubItemButton path="/settings/users" exact text="Users" onClick={this.close} />
                    <NavigationSubItemButton path="/settings/connections" exact text="Connections" onClick={this.close} />
                  </NavigationSectionButton>
                </Box>
                {!loading && (
                  <Box pad="small" align="center" flex={false}>
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
        if (!this.props.embeddedInPageHeader) {
          return null;
        }

        return (
          <>
            <Box>
              <Button
                icon={<Menu />}
                onClick={() => {
                  this.setState({ openForSmall: true });
                }}
              />
            </Box>
            {this.state.openForSmall && (
              <Layer full={true}>
                <Button icon={<FormClose />} onClick={this.close} style={{ position: "fixed", top: 0, right: 0 }} />
                {this.renderMenu()}
              </Layer>
            )}
          </>
        );
      } else {
        if (this.props.embeddedInPageHeader) {
          return null;
        }

        return (
          <Box fill="vertical" width="small" flex={false} background="light-2" className="AppSidebar-container">
            {this.renderMenu()}
          </Box>
        );
      }
    }
  }
);
