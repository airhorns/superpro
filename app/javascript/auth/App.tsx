import * as React from "react";
import { Grommet } from "grommet";
import { BrowserRouter as Router, Switch, Route } from "react-router-dom";
import { ApolloProvider } from "react-apollo";
import { SuperproGrommetTheme, SuperproGlobalStyle } from "../superlib/SuperproTheme";
import { NotFoundPage } from "./components/NotFoundPage";
import { LoginPage } from "./components/LoginPage";
import { Settings } from "./lib/settings";
import { client } from "./lib/apollo";
import { PrivateRoute } from "./components/PrivateRoute";
import { SentryErrorBoundary, FlagsProvider, PageLoadSpin, ToastContainer, SegmentIdentify } from "../superlib";

const HomePage = React.lazy(() => import(/* webpackPrefetch: true, webpackChunkName: "Auth" */ "./components/HomePage"));
const SignUpPage = React.lazy(() => import(/* webpackPrefetch: true, webpackChunkName: "Auth" */ "./components/SignUpPage"));
const NewAccountPage = React.lazy(() => import(/* webpackChunkName: "AuthNewAccount" */ "./components/NewAccountPage"));

export class App extends React.Component {
  public render() {
    const app = (
      <SegmentIdentify>
        <FlagsProvider flags={Settings.flags}>
          <Grommet full theme={SuperproGrommetTheme}>
            <SuperproGlobalStyle />
            <ApolloProvider client={client}>
              <ToastContainer>
                <Router basename={Settings.baseUrl}>
                  <React.Suspense fallback={<PageLoadSpin />}>
                    <Switch>
                      <Route path="/sign_up" exact component={SignUpPage} />
                      <Route path="/sign_in" exact component={LoginPage} />
                      <PrivateRoute path="/" exact component={HomePage} />
                      <PrivateRoute path="/new_account" exact component={NewAccountPage} />
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
