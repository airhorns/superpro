import React from "react";
import { Page } from ".";
import { VizDocumentCompiler, ReportDocument } from "app/components/superviz";

export const FullReportPage = (title: string, document: ReportDocument) => {
  const Component = new VizDocumentCompiler().compile(document);

  return class FullReportPage extends Page {
    render() {
      return (
        <Page.Layout title={title}>
          <Component />
        </Page.Layout>
      );
    }
  };
};
