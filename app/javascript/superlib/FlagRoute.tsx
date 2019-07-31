import React from "react";
import { RouteProps, Route } from "react-router";
import { Flag, FlagKeyPath } from "superlib";
import { omit } from "lodash";

export const FlagRoute = (props: RouteProps & { flag: FlagKeyPath }) => (
  <Flag name={props.flag}>
    <Route {...omit(props, "name")} />
  </Flag>
);
