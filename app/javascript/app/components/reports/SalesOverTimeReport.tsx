import React from "react";
import { Page } from "../common";
import { Compiler, Document } from "app/components/superviz";

const document: Document = {
  type: "document",
  id: "sales_over_time",
  blocks: [
    { type: "markdown_block", markdown: "A _test_ report." },
    {
      type: "viz_block",
      query: {
        measures: [
          { model: "Sales::OrderFacts", field: "total_price", operator: "sum", id: "total_price" },
          { model: "Sales::OrderFacts", field: "total_weight", operator: "sum", id: "total_weight" }
        ],
        dimensions: [{ model: "Sales::OrderFacts", field: "created_at", operator: "date_trunc_week", id: "date" }]
      },
      viz: {
        type: "viz",
        systems: [
          {
            type: "viz_system",
            vizType: "line",
            xId: "date",
            yId: "total_price"
          },
          {
            type: "viz_system",
            vizType: "line",
            xId: "date",
            yId: "total_weight"
          }
        ]
      }
    }
  ]
};

const Component = new Compiler().compile(document);

export default class SalesOverTimeReport extends Page {
  render() {
    return (
      <Page.Layout title="Sales Over Time">
        <Component />
      </Page.Layout>
    );
  }
}
