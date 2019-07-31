import React from "react";
import { ApolloProvider } from "react-apollo";
import { ApolloProvider as ApolloHooksProvider } from "react-apollo-hooks";
import { BrowserRouter as Router, Switch, Route } from "react-router-dom";
import { getClient } from "./lib/apollo";
import {
  SuperproGrommetTheme,
  SentryErrorBoundary,
  SuperproGlobalStyle,
  SegmentIdentify,
  HotkeysContainer,
  Flag,
  FlagRoute
} from "../superlib";
import { Grommet, Box } from "grommet";
import { Settings } from "./lib/settings";
import { ToastContainer, FlagsProvider } from "../superlib";
import { AppSidebar } from "./components/chrome/AppSidebar";
import { NotFoundPage } from "./components/chrome/NotFoundPage";
import { PageLoadSpin } from "../superlib";

const HomePage = React.lazy(() => import("./components/home/HomePage"));
const Launchpad = React.lazy(() => import("./components/home/Launchpad"));
const InviteUsersPage = React.lazy(() => import("./components/identity/InviteUsersPage"));
const BudgetReportsIndexPage = React.lazy(() => import("./components/budget/BudgetReportsIndexPage"));
const BudgetReportPage = React.lazy(() => import("./components/budget/BudgetReportPage"));
const EditBudgetPage = React.lazy(() => import("./components/budget/EditBudgetPage"));
const TodosIndexPage = React.lazy(() => import("./components/todos/TodosIndexPage"));
const ProcessRunsIndexPage = React.lazy(() => import("./components/todos/ProcessRunsIndexPage"));
const ProcessDocsIndexPage = React.lazy(() => import("./components/todos/ProcessDocsIndexPage"));
const CreateProcessDocPage = React.lazy(() => import("./components/todos/CreateProcessDocPage"));
const EditProcessDocPage = React.lazy(() => import("./components/todos/EditProcessDocPage"));
const StartProcessPage = React.lazy(() => import("./components/todos/StartProcessPage"));
const EditProcessRunPage = React.lazy(() => import("./components/todos/EditProcessRunPage"));
const UsersSettingsPage = React.lazy(() => import("./components/identity/UsersSettingsPage"));
const AccountSettingsPage = React.lazy(() => import("./components/identity/AccountSettingsPage"));
const ConnectionsIndexPage = React.lazy(() => import("./components/identity/connections/ConnectionsIndexPage"));

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
                          <FlagRoute path="/budget" exact component={EditBudgetPage} flag={["feature.budgets"]} />
                          <FlagRoute path="/budget/reports" exact component={BudgetReportsIndexPage} flag={["feature.budgets"]} />
                          <FlagRoute path="/budget/reports/:reportKey" exact component={BudgetReportPage} flag={["feature.budgets"]} />
                          <FlagRoute path="/todos" exact component={TodosIndexPage} flag={["feature.todos"]} />
                          <FlagRoute path="/todos/process/docs" exact component={ProcessDocsIndexPage} flag={["feature.todos"]} />
                          <FlagRoute path="/todos/process/docs/new" exact component={CreateProcessDocPage} flag={["feature.todos"]} />
                          <FlagRoute path="/todos/process/docs/:id" exact component={EditProcessDocPage} flag={["feature.todos"]} />
                          <FlagRoute path="/todos/process/docs/:id/start" exact component={StartProcessPage} flag={["feature.todos"]} />
                          <FlagRoute path="/todos/process/runs" exact component={ProcessRunsIndexPage} flag={["feature.todos"]} />
                          <FlagRoute path="/todos/process/runs/:id" exact component={EditProcessRunPage} flag={["feature.todos"]} />
                          <Route path="/settings" exact component={AccountSettingsPage} />
                          <Route path="/settings/account" exact component={AccountSettingsPage} />
                          <Route path="/settings/users" exact component={UsersSettingsPage} />
                          <FlagRoute path="/settings/connections" exact component={ConnectionsIndexPage} flag={["feature.connections"]} />
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
