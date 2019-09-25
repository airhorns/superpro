import React from "react";
import { Page } from "../common";
import { VizDocumentCompiler, Document } from "app/components/superviz";

export const FullReportPage = (title: string, document: Document) => {
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
