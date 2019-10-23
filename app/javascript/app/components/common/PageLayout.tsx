import React from "react";
import { Box, Heading, Text } from "grommet";
import { edgeStyle } from "grommet/utils/styles";
import { Link } from "react-router-dom";
import { Helmet } from "react-helmet";
import { Row, SuperproGrommetTheme } from "superlib";
import { AppSidebar } from "../chrome/AppSidebar";
import styled from "styled-components";

const StaticBreadcrumbs = {
  home: { text: "Home", path: "/" },
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
  children?: React.ReactNode;
  documentTitle?: string;
  padded?: boolean;
  scrolly?: boolean;
  headerExtra?: React.ReactNode;
  breadcrumbs?: Breadcrumb[];
}

function isCustomCrumb(crumb: Breadcrumb): crumb is BreadcrumbDescriptor {
  return crumb.hasOwnProperty("text");
}

const PageLayoutBreadcrumbs = (props: PageLayoutProps) => {
  if (!props.breadcrumbs) {
    return null;
  }

  const routes = props.breadcrumbs.map(crumb => {
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
};

export const PageLayoutContainer = styled(Box)`
  height: 100%;
  width: 100%;

  @media print {
    height: auto;
    display: block;
  }
`;

export const PageLayoutContent = styled.div`
  flex: 1 1;
  width: 100%;
  overflow: auto;
  display: flex;
  flex-direction: column;
  ${edgeStyle("padding", "medium", false, SuperproGrommetTheme.box.responsiveBreakpoint, SuperproGrommetTheme)}

  @media print {
    height: auto;
    display: block;
    overflow: visible;
  }
`;

export const PageLayout = (props: PageLayoutProps) => {
  React.useEffect(() => {
    analytics.page(props.documentTitle || (props.title as string));
  }, [props.title, props.documentTitle]);

  return (
    <PageLayoutContainer className="PageLayout-container">
      <Helmet>
        <title>{props.documentTitle || props.title} - Superpro</title>
      </Helmet>
      <PageLayoutBreadcrumbs {...props} />
      <Row
        tag="header"
        background="white"
        align="center"
        justify="between"
        pad={{ horizontal: "small", bottom: "small", top: props.breadcrumbs ? undefined : "small" }}
        responsive={false}
        style={{ position: "relative" }}
        border={{ color: "light-2", side: "bottom" }}
        className="PageLayout-header"
        flex={false}
      >
        <Row>
          <AppSidebar embeddedInPageHeader={true} />
          <Heading level={"3"} margin="xsmall">
            {props.title}
          </Heading>
        </Row>

        <Row>{props.headerExtra}</Row>
      </Row>
      <PageLayoutContent className="PageLayout-content">{props.children}</PageLayoutContent>
    </PageLayoutContainer>
  );
};

PageLayout.defaultProps = {
  padded: true,
  scrolly: true
};
