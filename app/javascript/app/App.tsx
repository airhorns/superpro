import React from "react";
import { ApolloProvider } from "react-apollo";
import { DragDropContextProvider } from "react-dnd";
import { BrowserRouter as Router, Switch, Route } from "react-router-dom";
import { getClient } from "./lib/apollo";
import { FlurishGrommetTheme, SentryErrorBoundary, FlurishGlobalStyle, DnDBackendForDevice } from "../flurishlib";
import { Grommet, Box } from "grommet";
import { Settings } from "./lib/settings";
import { ToastContainer, FlagsProvider, flags } from "../flurishlib";
import { AppSidebar } from "./components/chrome/AppSidebar";
import { NotFoundPage } from "./components/chrome/NotFoundPage";
import { PageLoadSpin } from "../flurishlib";

const HomePage = React.lazy(() => import(/* webpackPrefetch: true, webpackChunkName: "Home" */ "./components/home/HomePage"));
const BudgetReportsIndexPage = React.lazy(() =>
  import(/* webpackPrefetch: true, webpackChunkName: "Budget" */ "./components/budget/BudgetReportsIndexPage")
);
const BudgetReportPage = React.lazy(() =>
  import(/* webpackPrefetch: true, webpackChunkName: "Budget" */ "./components/budget/BudgetReportPage")
);
const EditBudgetPage = React.lazy(() =>
  import(/* webpackPrefetch: true, webpackChunkName: "Budget" */ "./components/budget/EditBudgetPage")
);

export const FlurishClient = getClient();

export const App = () => {
  const app = (
    <FlagsProvider flags={flags}>
      <ApolloProvider client={FlurishClient}>
        <DragDropContextProvider backend={DnDBackendForDevice()}>
          <Grommet theme={FlurishGrommetTheme}>
            <FlurishGlobalStyle />
            <Router basename={Settings.baseUrl}>
              <ToastContainer>
                <Box fill direction="row-responsive" id="flurish-root" style={{ width: "100vw", height: "100vh" }}>
                  <AppSidebar />
                  <Box flex overflow={{ vertical: "auto" }}>
                    <React.Suspense fallback={<PageLoadSpin />}>
                      <Switch>
                        <Route path="/" exact component={HomePage} />
                        <Route path="/budget" exact component={EditBudgetPage} />
                        <Route path="/budget/:budgetId/reports" exact component={BudgetReportsIndexPage} />
                        <Route path="/budget/:budgetId/report/:reportKey" exact component={BudgetReportPage} />
                        <Route component={NotFoundPage} />
                      </Switch>
                    </React.Suspense>
                  </Box>
                </Box>
              </ToastContainer>
            </Router>
          </Grommet>
        </DragDropContextProvider>
      </ApolloProvider>
    </FlagsProvider>
  );

  if (!Settings.devMode) {
    return <SentryErrorBoundary>{app}</SentryErrorBoundary>;
  } else {
    return app;
  }
};
