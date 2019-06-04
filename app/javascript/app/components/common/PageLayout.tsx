import React from "react";
import { Box, Heading } from "grommet";
import { Link } from "react-router-dom";
import { Helmet } from "react-helmet";

const StaticBreadcrumbs = {
  home: { text: "Home", path: "/" },
  entities: { text: "Entities", path: "/entities" },
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

  breadcrumbs() {
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

    return {
      routes,
      itemRender(route: Route, _params: any, routes: Route[]) {
        const isLastItem = routes.indexOf(route) === routes.length - 1;
        return route.path && !isLastItem ? <Link to={route.path}>{route.text}</Link> : <span>{route.text}</span>;
      }
    };
  }

  render() {
    return (
      <Box flex>
        <Helmet>
          <title>{this.props.documentTitle || this.props.title} - Flurish</title>
        </Helmet>
        <Box
          tag="header"
          direction="row"
          background="white"
          align="center"
          alignContent="center"
          justify="between"
          pad="small"
          responsive={false}
          style={{ position: "relative" }}
          border={{ color: "light-2", side: "bottom" }}
        >
          <Heading level={"3"} margin="xsmall">
            {this.props.title}
          </Heading>
          <Box alignSelf="end" direction="row">
            {this.props.headerExtra}
          </Box>
        </Box>
        <Box flex pad={this.props.padded ? "medium" : undefined}>
          {this.props.children}
        </Box>
      </Box>
    );
  }
}
