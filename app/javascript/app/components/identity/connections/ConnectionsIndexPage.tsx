import React from "react";
import { Page } from "../../common";
import { ConnectionsIndexContent } from "./ConnectionsIndexContent";

export default class ConnectionsIndexPage extends Page {
  render() {
    return (
      <Page.Layout title="Connection Settings">
        <ConnectionsIndexContent {...this.props} />
      </Page.Layout>
    );
  }
}
