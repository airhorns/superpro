import React from "react";
import { ApolloProvider } from "react-apollo";
import { BrowserRouter as Router, Switch, Route } from "react-router-dom";
import { getClient } from "./lib/apollo";
import { FlurishGrommetTheme, SentryErrorBoundary, FlurishGlobalStyle, SegmentIdentify, HotkeysContainer } from "../flurishlib";
import { Grommet, Box } from "grommet";
import { Settings } from "./lib/settings";
import { ToastContainer, FlagsProvider, flags } from "../flurishlib";
import { AppSidebar } from "./components/chrome/AppSidebar";
import { NotFoundPage } from "./components/chrome/NotFoundPage";
import { PageLoadSpin } from "../flurishlib";

const HomePage = React.lazy(() => import(/* webpackPrefetch: true, webpackChunkName: "Home" */ "./components/home/HomePage"));
const Launchpad = React.lazy(() => import(/* webpackPrefetch: true, webpackChunkName: "Home" */ "./components/home/Launchpad"));
const BudgetReportsIndexPage = React.lazy(() =>
  import(/* webpackPrefetch: true, webpackChunkName: "Budget" */ "./components/budget/BudgetReportsIndexPage")
);
const BudgetReportPage = React.lazy(() =>
  import(/* webpackPrefetch: true, webpackChunkName: "Budget" */ "./components/budget/BudgetReportPage")
);
const EditBudgetPage = React.lazy(() =>
  import(/* webpackPrefetch: true, webpackChunkName: "Budget" */ "./components/budget/EditBudgetPage")
);
const ProcessesIndexPage = React.lazy(() =>
  import(/* webpackPrefetch: true, webpackChunkName: "Process" */ "./components/tasks/ProcessesIndexPage")
);
const EditProcessPage = React.lazy(() =>
  import(/* webpackPrefetch: true, webpackChunkName: "Process" */ "./components/tasks/EditProcessPage")
);

export const FlurishClient = getClient();

export const App = () => {
  const app = (
    <SegmentIdentify>
      <FlagsProvider flags={flags}>
        <ApolloProvider client={FlurishClient}>
          <Grommet theme={FlurishGrommetTheme}>
            <FlurishGlobalStyle />
            <Router basename={Settings.baseUrl}>
              <ToastContainer>
                <HotkeysContainer>
                  <Box fill direction="row-responsive" id="flurish-root" style={{ width: "100vw", height: "100vh" }}>
                    <AppSidebar />
                    <Box flex overflow={{ vertical: "auto" }}>
                      <React.Suspense fallback={<PageLoadSpin />}>
                        <Switch>
                          <Route path="/" exact component={HomePage} />
                          <Route path="/launchpad" exact component={Launchpad} />
                          <Route path="/budget" exact component={EditBudgetPage} />
                          <Route path="/budget/reports" exact component={BudgetReportsIndexPage} />
                          <Route path="/budget/reports/:reportKey" exact component={BudgetReportPage} />
                          <Route path="/tasks/processes" exact component={ProcessesIndexPage} />
                          <Route path="/tasks/processes/new" exact component={EditProcessPage} />
                          <Route component={NotFoundPage} />
                        </Switch>
                      </React.Suspense>
                    </Box>
                  </Box>
                </HotkeysContainer>
              </ToastContainer>
            </Router>
          </Grommet>
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
