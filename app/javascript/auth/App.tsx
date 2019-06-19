import * as React from "react";
import { Grommet } from "grommet";
import { BrowserRouter as Router, Switch, Route } from "react-router-dom";
import { ApolloProvider } from "react-apollo";
import { FlurishGrommetTheme, FlurishGlobalStyle } from "../flurishlib/FlurishTheme";
import { NotFoundPage } from "./components/NotFoundPage";
import { LoginPage } from "./components/LoginPage";
import { Settings } from "./lib/settings";
import { client } from "./lib/apollo";
import { PrivateRoute } from "./components/PrivateRoute";
import { SentryErrorBoundary, FlagsProvider, flags, PageLoadSpin, ToastContainer, SegmentIdentify } from "../flurishlib";

const HomePage = React.lazy(() => import(/* webpackPrefetch: true, webpackChunkName: "AuthHome" */ "./components/HomePage"));
const SignUpPage = React.lazy(() => import(/* webpackPrefetch: true, webpackChunkName: "AuthNewApp" */ "./components/SignUpPage"));

export class App extends React.Component {
  public render() {
    const app = (
      <SegmentIdentify>
        <FlagsProvider flags={flags}>
          <Grommet full theme={FlurishGrommetTheme}>
            <FlurishGlobalStyle />
            <ApolloProvider client={client}>
              <ToastContainer>
                <Router basename={Settings.baseUrl}>
                  <React.Suspense fallback={<PageLoadSpin />}>
                    <Switch>
                      <Route path="/sign_up" exact component={SignUpPage} />
                      <Route path="/sign_in" exact component={LoginPage} />
                      <PrivateRoute path="/" exact component={HomePage} />
                      <Route component={NotFoundPage} />
                    </Switch>
                  </React.Suspense>
                </Router>
              </ToastContainer>
            </ApolloProvider>
          </Grommet>
        </FlagsProvider>
      </SegmentIdentify>
    );

    if (!Settings.devMode) {
      return <SentryErrorBoundary>{app}</SentryErrorBoundary>;
    } else {
      return app;
    }
  }
}
