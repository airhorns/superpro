import React from "react";
import { Page } from "../../common";
import { Alert } from "superlib";

export default (_props: {}) => {
  return (
    <Page.Layout title="Connection Error">
      <Alert type="error" message="There was an internal error completing this connection. Please try again" />
    </Page.Layout>
  );
};
