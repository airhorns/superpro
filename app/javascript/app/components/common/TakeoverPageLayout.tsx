import React from "react";
import { Box, Heading } from "grommet";
import { Helmet } from "react-helmet";
import { Row } from "superlib";
import { AppSidebar } from "../chrome/AppSidebar";

export class TakeoverPageLayout extends React.Component<{ title?: React.ReactNode; documentTitle?: string }> {
  componentDidMount() {
    analytics.page(this.props.documentTitle || (this.props.title as string));
  }

  render() {
    return (
      <Box fill className="TakeoutPageLayout-container" background="light-2" align="center" justify="center" pad="large">
        <Helmet>
          <title>{this.props.documentTitle || this.props.title} - Superpro</title>
        </Helmet>
        <Box fill pad="medium" background="white" elevation="small">
          {this.props.title && (
            <Row
              tag="header"
              background="white"
              align="center"
              justify="between"
              pad={{ horizontal: "small", bottom: "small" }}
              responsive={false}
              style={{ position: "relative" }}
              border={{ color: "light-2", side: "bottom" }}
              className="TakeoverPageLayout-header"
              flex={false}
            >
              <Row>
                <AppSidebar embeddedInPageHeader={true} />
                <Heading level={"3"} margin="xsmall">
                  {this.props.title}
                </Heading>
              </Row>
            </Row>
          )}
          <Box flex pad={"medium"} className="PageLayout-content" overflow={{ vertical: "auto" }}>
            {this.props.children}
          </Box>
        </Box>
      </Box>
    );
  }
}
