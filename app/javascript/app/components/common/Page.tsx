import React from "react";
import { RouteComponentProps } from "react-router";
import { PageLayout } from "./PageLayout";
import { TakeoverPageLayout } from "./TakeoverPageLayout";
import { PageLoad } from "./PageLoad";

export class Page<Params = {}, S = {}> extends React.Component<RouteComponentProps<Params>, S> {
  static Load = PageLoad;
  static Layout = PageLayout;
  static TakeoverLayout = TakeoverPageLayout;
}
