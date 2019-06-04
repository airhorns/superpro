import * as React from "react";
import { Page } from "../common";

export class NotFoundPage extends React.Component {
  public render() {
    return (
      <Page.Layout title="Page Not Found">
        <h3>Sorry about that</h3>
      </Page.Layout>
    );
  }
}
