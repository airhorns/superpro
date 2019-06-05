import React from "react";
import { ApolloProvider } from "react-apollo";
import { DragDropContextProvider } from "react-dnd";
import { BrowserRouter as Router, Switch, Route } from "react-router-dom";
import { getClient } from "../lib/apollo";
import { FlurishGrommetTheme, SentryErrorBoundary, FlurishGlobalStyle, DnDBackendForDevice } from "../../flurishlib";
import { Grommet, Box } from "grommet";
import { Settings } from "../lib/settings";
import { ToastContainer, FlagsProvider, flags } from "../../flurishlib";
import { AppSidebar } from "./chrome/AppSidebar";
import { NotFoundPage } from "./chrome/NotFoundPage";
import { PageLoadSpin } from "../../flurishlib";

const HomePage = React.lazy(() => import(/* webpackPrefetch: true, webpackChunkName: "Home" */ "./home/HomePage"));
const NewBudgetPage = React.lazy(() => import(/* webpackPrefetch: true, webpackChunkName: "Budget" */ "./budget/NewBudgetPage"));
const EditBudgetPage = React.lazy(() => import(/* webpackPrefetch: true, webpackChunkName: "Budget" */ "./budget/EditBudgetPage"));

export const FlurishClient = getClient();

export class App extends React.Component {
  public render() {
    const app = (
      <FlagsProvider flags={flags}>
        <ApolloProvider client={FlurishClient}>
          <DragDropContextProvider backend={DnDBackendForDevice()}>
            <Grommet full theme={FlurishGrommetTheme}>
              <FlurishGlobalStyle />
              <Router basename={Settings.baseUrl}>
                <ToastContainer>
                  <Box fill direction="row">
                    <AppSidebar />
                    <Box flex>
                      <React.Suspense fallback={<PageLoadSpin />}>
                        <Switch>
                          <Route path="/" exact component={HomePage} />
                          <Route path="/budget" exact component={NewBudgetPage} />
                          <Route path="/budget/:budgetId" exact component={EditBudgetPage} />
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
  }
}
