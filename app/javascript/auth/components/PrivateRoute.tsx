import { omit } from "lodash";
import React from "react";
import { Route, Redirect, RouteProps, RouteComponentProps } from "react-router";
import { Settings } from "../lib/settings";

export const PrivateRoute = (routeProps: RouteProps & { component: React.ComponentType<RouteComponentProps<any>> }) => {
  return (
    <Route
      {...omit(routeProps, "component")}
      render={props =>
        Settings.signedIn ? (
          <routeProps.component {...props} />
        ) : (
          <Redirect
            to={{
              pathname: "/sign_in"
            }}
          />
        )
      }
    />
  );
};
