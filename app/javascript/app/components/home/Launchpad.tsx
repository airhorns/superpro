import React from "react";
import { Page } from "../common";
import { Paragraph, Box, Heading } from "grommet";
import { Row, LinkButton } from "superlib";
import { Add } from "../common/SuperproIcons";

const StartCard = (props: { title: string; destination: string }) => (
  <LinkButton to={props.destination} hoverIndicator>
    <Box pad="small" align="center">
      <Box pad="medium" color="light-4">
        <Add />
      </Box>
      <Heading>{props.title}</Heading>
    </Box>
  </LinkButton>
);

export default class HomePage extends Page {
  render() {
    return (
      <Page.Layout title="Launchpad">
        <Box align="center">
          <Paragraph>Welcome to Superpro! Let&apos;s get started.</Paragraph>
          <Row gap="medium">
            <StartCard title="Create a Budget" destination="/budget" />
            <StartCard title="Start a Process" destination="/todos/process/docs/new" />
          </Row>
        </Box>
      </Page.Layout>
    );
  }
}
