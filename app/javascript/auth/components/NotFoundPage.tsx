import * as React from "react";
import { Heading } from "grommet";
import { PageBox } from "./PageBox";

export class NotFoundPage extends React.Component {
  public render() {
    return (
      <PageBox documentTitle="Not Found">
        <Heading level="1">Page Not Found</Heading>
        <Heading level="3">Sorry about that.</Heading>
      </PageBox>
    );
  }
}
