import React from "react";
import { ApolloProvider } from "@apollo/react-components";
import { ApolloProvider as ApolloHooksProvider } from "@apollo/react-hooks";
import { BrowserRouter as Router, Switch, Route, Redirect } from "react-router-dom";
import { getClient } from "./lib/apollo";
import { SuperproGrommetTheme, SentryErrorBoundary, SuperproGlobalStyle, SegmentIdentify, HotkeysContainer, Flag } from "../superlib";
import { Grommet, Box } from "grommet";
import useDetectPrint from "use-detect-print";
import { Settings } from "./lib/settings";
import { ToastContainer, FlagsProvider } from "../superlib";
import { AppSidebar } from "./components/chrome/AppSidebar";
import { NotFoundPage } from "./components/chrome/NotFoundPage";
import { PageLoadSpin } from "../superlib";

import MarketingActivityCustomerQualityReport from "./components/traffic/MarketingActivityCustomerQualityReport";

const HomePage = React.lazy(() => import("./components/home/HomePage"));
const Launchpad = React.lazy(() => import("./components/home/Launchpad"));
const WelcomePage = React.lazy(() => import("./components/onboarding/WelcomePage"));
const ConnectionsSetupPage = React.lazy(() => import("./components/onboarding/ConnectionsSetupChromelessPage"));
const InviteUsersPage = React.lazy(() => import("./components/identity/InviteUsersPage"));
const UsersSettingsPage = React.lazy(() => import("./components/identity/UsersSettingsPage"));
const AccountSettingsPage = React.lazy(() => import("./components/identity/AccountSettingsPage"));
const ConnectionsIndexPage = React.lazy(() => import("./components/identity/connections/ConnectionsIndexPage"));
const ConnectionCompletionErrorPage = React.lazy(() => import("./components/identity/connections/ConnectionCompletionErrorPage"));
const GoogleAnalyticsCompletePage = React.lazy(() => import("./components/identity/connections/GoogleAnalyticsCompletePage"));
const FacebookCompletePage = React.lazy(() => import("./components/identity/connections/FacebookCompletePage"));
const MicroOrderTimingReport = React.lazy(() => import("./components/sales/MicroOrderTimingReport"));
const SalesOverviewReport = React.lazy(() => import("./components/sales/SalesOverviewReport"));
const YearlyOrdersReviewReport = React.lazy(() => import("./components/sales/YearlyOrdersReviewReport"));
const RepurchaseRatesReport = React.lazy(() => import("./components/sales/RepurchaseRatesReport"));
const TrafficOverviewReport = React.lazy(() => import("./components/traffic/TrafficOverviewReport"));
const SlowLandingPagesReport = React.lazy(() => import("./components/traffic/SlowLandingPagesReport"));
const RFMBreakdownReport = React.lazy(() => import("./components/customers/RFMBreakdownReport"));
const ReporrtBuilderPage = React.lazy(() => import("./components/report_builder/ReportBuilderPage"));

export const SuperproClient = getClient();

export const App = () => {
  const printing = useDetectPrint();

  const app = (
    <SegmentIdentify>
      <FlagsProvider flags={Settings.flags}>
        <ApolloProvider client={SuperproClient}>
          <ApolloHooksProvider client={SuperproClient}>
            <Grommet theme={SuperproGrommetTheme} style={{ width: "100vw", height: "100vh", overflow: printing ? "auto" : "hidden" }}>
              <SuperproGlobalStyle />
              <Router basename={Settings.baseUrl}>
                <ToastContainer>
                  <HotkeysContainer>
                    <React.Suspense fallback={<PageLoadSpin />}>
                      <Box fill direction="row-responsive" id="Superpro-Layout">
                        <Switch>
                          <Route path="/s">
                            <Switch>
                              <Route path="/s/welcome" exact component={WelcomePage} />
                              <Route path="/s/connection_setup" exact component={ConnectionsSetupPage} />
                              <Route path="/s/connections/error" exact component={ConnectionCompletionErrorPage} />
                              <Route
                                path="/s/connections/google_analytics/:credentialId/complete"
                                exact
                                component={GoogleAnalyticsCompletePage}
                              />
                              <Route path="/s/connections/facebook/:facebookAdAccountId/complete" exact component={FacebookCompletePage} />
                              <Route component={NotFoundPage} />
                            </Switch>
                          </Route>
                          <Route>
                            <Flag
                              name={["gate.productAccess"]}
                              fallbackRender={() => (
                                <Switch>
                                  <Route path="/" exact>
                                    <Redirect to="/s/welcome" />
                                  </Route>
                                  <Route component={NotFoundPage} />
                                </Switch>
                              )}
                            >
                              <AppSidebar embeddedInPageHeader={false} />
                              <Switch>
                                <Route path="/" exact component={HomePage} />
                                <Route path="/launchpad" exact component={Launchpad} />
                                <Route path="/invite" exact component={InviteUsersPage} />
                                <Route path="/sales" exact component={SalesOverviewReport} />
                                <Route path="/sales/overview" exact component={SalesOverviewReport} />
                                <Route path="/sales/yearly_review" exact component={YearlyOrdersReviewReport} />
                                <Route path="/sales/repurchase_rates" exact component={RepurchaseRatesReport} />
                                <Route path="/sales/micro_order_timing" exact component={MicroOrderTimingReport} />
                                <Route path="/traffic" exact component={TrafficOverviewReport} />
                                <Route path="/traffic/overview" exact component={TrafficOverviewReport} />
                                <Route path="/traffic/slow_landing_pages" exact component={SlowLandingPagesReport} />
                                <Route
                                  path="/traffic/marketing_activity_customer_quality"
                                  exact
                                  component={MarketingActivityCustomerQualityReport}
                                />
                                <Route path="/customers/rfm_breakdown" exact component={RFMBreakdownReport} />
                                <Route path="/report_builder" exact component={ReporrtBuilderPage} />
                                <Route path="/settings" exact component={AccountSettingsPage} />
                                <Route path="/settings/account" exact component={AccountSettingsPage} />
                                <Route path="/settings/users" exact component={UsersSettingsPage} />
                                <Route path="/settings/connections" exact component={ConnectionsIndexPage} />
                                <Route component={NotFoundPage} />
                              </Switch>
                            </Flag>
                          </Route>
                        </Switch>
                      </Box>
                    </React.Suspense>
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
