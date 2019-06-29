import React from "react";
import { Box, Heading, Text } from "grommet";
import { Link } from "react-router-dom";
import { Helmet } from "react-helmet";
import { Row } from "flurishlib";

const StaticBreadcrumbs = {
  home: { text: "Home", path: "/" },
  budget: { text: "Budget", path: "/budget" },
  processes: { text: "Processes", path: "/todos/processes" },
  settings: { text: "Settings", path: null },
  connectionSettings: { text: "Connections", path: "/settings/connections" }
};

export interface BreadcrumbDescriptor {
  text: React.ReactNode;
  path: string | null;
}
export type Breadcrumb = keyof typeof StaticBreadcrumbs | BreadcrumbDescriptor;

interface Route {
  path?: string;
  text: React.ReactNode;
}

export interface PageLayoutProps {
  title: React.ReactNode;
  documentTitle?: string;
  padded?: boolean;
  headerExtra?: React.ReactNode;
  breadcrumbs?: Breadcrumb[];
}

function isCustomCrumb(crumb: Breadcrumb): crumb is BreadcrumbDescriptor {
  return crumb.hasOwnProperty("text");
}

export class PageLayout extends React.Component<PageLayoutProps> {
  static defaultProps = {
    padded: true,
    fullHeight: false
  };

  renderBreadcrumbs() {
    if (!this.props.breadcrumbs) {
      return;
    }

    const routes = this.props.breadcrumbs.map(crumb => {
      let text: React.ReactNode;
      let path: string | null;
      if (isCustomCrumb(crumb)) {
        text = crumb.text;
        path = crumb.path;
      } else {
        text = StaticBreadcrumbs[crumb].text;
        path = StaticBreadcrumbs[crumb].path;
      }

      return {
        path: path,
        text: text,
        breadcrumbName: path || text
      };
    });

    routes.unshift({ path: "/", text: "Home", breadcrumbName: "fixed-home" });
    const lastIndex = routes.length - 1;

    return (
      <Row margin={{ top: "xsmall", left: "small" }}>
        {routes.map((route, index) => (
          <Row key={index}>
            <Text size="small">{route.path ? <Link to={route.path}>{route.text}</Link> : route.text}</Text>
            <Box pad={{ horizontal: "xsmall" }}>{index == lastIndex ? null : <Text size="small">/</Text>}</Box>
          </Row>
        ))}
      </Row>
    );
  }

  componentDidMount() {
    analytics.page(this.props.documentTitle || (this.props.title as string));
  }

  render() {
    const breadcrumbs = this.renderBreadcrumbs();
    return (
      <Box flex className="PageLayout-container">
        <Helmet>
          <title>{this.props.documentTitle || this.props.title} - Flurish</title>
        </Helmet>
        {breadcrumbs}
        <Row
          tag="header"
          background="white"
          align="center"
          justify="between"
          pad={{ horizontal: "small", bottom: "small", top: breadcrumbs ? undefined : "small" }}
          responsive={false}
          style={{ position: "relative" }}
          border={{ color: "light-2", side: "bottom" }}
          className="PageLayout-header"
        >
          <Heading level={"3"} margin="xsmall">
            {this.props.title}
          </Heading>
          <Row>{this.props.headerExtra}</Row>
        </Row>
        <Box flex pad={this.props.padded ? "medium" : undefined} className="PageLayout-content">
          {this.props.children}
        </Box>
      </Box>
    );
  }
}
