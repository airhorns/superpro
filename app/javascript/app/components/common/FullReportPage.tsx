import React from "react";
import { Page } from ".";
import { VizDocumentCompiler, ReportDocument, GlobalFilterController } from "app/components/superviz";
import { GetWarehouseFilters } from "../superviz/components/filter/GetWarehouseFilters";

export const FullReportPage = (title: string, document: ReportDocument) => {
  return class FullReportPage extends Page {
    render() {
      return (
        <GetWarehouseFilters>
          {filters => {
            const compiler = new VizDocumentCompiler(filters, document);
            const Report = compiler.compileReport();
            const Filters = compiler.compileFilterControls();

            return (
              <GlobalFilterController.Provider>
                <Page.Layout title={title} headerExtra={<Filters />}>
                  <Report />
                </Page.Layout>
              </GlobalFilterController.Provider>
            );
          }}
        </GetWarehouseFilters>
      );
    }
  };
};
