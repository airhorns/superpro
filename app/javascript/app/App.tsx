import React from "react";
import { ApolloProvider } from "react-apollo";
import { ApolloProvider as ApolloHooksProvider } from "react-apollo-hooks";
import { BrowserRouter as Router, Switch, Route } from "react-router-dom";
import { getClient } from "./lib/apollo";
import { SuperproGrommetTheme, SentryErrorBoundary, SuperproGlobalStyle, SegmentIdentify, HotkeysContainer } from "../superlib";
import { Grommet, Box } from "grommet";
import { Settings } from "./lib/settings";
import { ToastContainer, FlagsProvider } from "../superlib";
import { AppSidebar } from "./components/chrome/AppSidebar";
import { NotFoundPage } from "./components/chrome/NotFoundPage";
import { PageLoadSpin } from "../superlib";

const HomePage = React.lazy(() => import("./components/home/HomePage"));
const Launchpad = React.lazy(() => import("./components/home/Launchpad"));
const InviteUsersPage = React.lazy(() => import("./components/identity/InviteUsersPage"));
const UsersSettingsPage = React.lazy(() => import("./components/identity/UsersSettingsPage"));
const AccountSettingsPage = React.lazy(() => import("./components/identity/AccountSettingsPage"));
const ConnectionsIndexPage = React.lazy(() => import("./components/identity/connections/ConnectionsIndexPage"));
const ConnectionCompletionErrorPage = React.lazy(() => import("./components/identity/connections/ConnectionCompletionErrorPage"));
const GoogleAnalyticsCompletePage = React.lazy(() => import("./components/identity/connections/GoogleAnalyticsCompletePage"));
const SalesOverTimeReport = React.lazy(() => import("./components/reports/SalesOverTimeReport"));
const OrdersReviewReport = React.lazy(() => import("./components/reports/OrdersReviewReport"));

export const SuperproClient = getClient();

export const App = () => {
  const app = (
    <SegmentIdentify>
      <FlagsProvider flags={Settings.flags}>
        <ApolloProvider client={SuperproClient}>
          <ApolloHooksProvider client={SuperproClient}>
            <Grommet theme={SuperproGrommetTheme} style={{ width: "100vw", height: "100vh", overflow: "hidden" }}>
              <SuperproGlobalStyle />
              <Router basename={Settings.baseUrl}>
                <ToastContainer>
                  <HotkeysContainer>
                    <Box fill direction="row-responsive" id="Superpro-Layout">
                      <AppSidebar embeddedInPageHeader={false} />
                      <React.Suspense fallback={<PageLoadSpin />}>
                        <Switch>
                          <Route path="/" exact component={HomePage} />
                          <Route path="/launchpad" exact component={Launchpad} />
                          <Route path="/invite" exact component={InviteUsersPage} />
                          <Route path="/reports/sales_over_time" exact component={SalesOverTimeReport} />
                          <Route path="/reports/orders_review" exact component={OrdersReviewReport} />
                          <Route path="/settings" exact component={AccountSettingsPage} />
                          <Route path="/settings/account" exact component={AccountSettingsPage} />
                          <Route path="/settings/users" exact component={UsersSettingsPage} />
                          <Route path="/settings/connections" exact component={ConnectionsIndexPage} />
                          <Route path="/settings/connections/error" exact component={ConnectionCompletionErrorPage} />
                          <Route
                            path="/settings/connections/google_analytics/:credentialId/complete"
                            exact
                            component={GoogleAnalyticsCompletePage}
                          />
                          <Route component={NotFoundPage} />
                        </Switch>
                      </React.Suspense>
                    </Box>
                  </HotkeysContainer>
                </ToastContainer>
              </Router>
            </Grommet>
          </ApolloHooksProvider>
        </ApolloProvider>
      </FlagsProvider>
    </SegmentIdentify>
  );

  if (!Settings.devMode) {
    return <SentryErrorBoundary>{app}</SentryErrorBoundary>;
  } else {
    return app;
  }
};
