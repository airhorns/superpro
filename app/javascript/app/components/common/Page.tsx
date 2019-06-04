import * as React from "react";
import { RouteComponentProps } from "react-router";
import { SimpleQuery } from "../../../flurishlib/SimpleQuery";
import { PageLayout } from "./PageLayout";

export class Page<Params = {}, S = {}> extends React.Component<RouteComponentProps<Params>, S> {
  static Load = SimpleQuery;
  static Layout = PageLayout;
}
