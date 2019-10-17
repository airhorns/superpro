import React from "react";
import { Page } from "../common";
import { ReportBuilder } from "../superviz/components/builder/ReportBuilder";
import gql from "graphql-tag";
import { ReportBuilderPageComponent } from "app/app-graph";
import { Warehouse } from "../superviz/Warehouse";

gql`
  query ReportBuilderPage {
    ...WarehouseIntrospectionForWarehouse
  }
`;

export default class ReportBuilderPage extends Page {
  render() {
    return (
      <Page.Layout title="Report Builder">
        <Page.Load component={ReportBuilderPageComponent} require={["warehouseIntrospection"]}>
          {data => {
            const warehouse = new Warehouse(data.warehouseIntrospection);
            return <ReportBuilder warehouse={warehouse} />;
          }}
        </Page.Load>
      </Page.Layout>
    );
  }
}
