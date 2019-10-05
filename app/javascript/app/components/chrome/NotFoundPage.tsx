import * as React from "react";
import { Page } from "../common";
import { Box, Image, Paragraph, Heading } from "grommet";
import NotFoundImage from "images/not-found.png";
import { Row } from "superlib";

export class NotFoundPage extends Page {
  public render() {
    return (
      <Page.Layout title="" documentTitle="Page Not Found">
        <Row gap="large">
          <Box width="large" height="large">
            <Image src={NotFoundImage} fit="contain" />
          </Box>
          <Box gap="medium">
            <Heading>Page Not Found</Heading>
            <Paragraph>Sorry about that there eh.</Paragraph>
          </Box>
        </Row>
      </Page.Layout>
    );
  }
}
