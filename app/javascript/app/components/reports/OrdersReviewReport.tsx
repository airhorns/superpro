import React from "react";
import { Page } from "../common";
import { VizDocumentCompiler, Document } from "app/components/superviz";

const document: Document = {
  type: "document",
  id: "orders_review",
  blocks: [
    { type: "markdown_block", markdown: "This report breaks down the long term health of the business based on sales data." },
    {
      type: "table_block",
      title: "Lifetime Summary",
      query: {
        measures: [
          { model: "Sales::OrderFacts", field: "total_price", operator: "sum", id: "total_price" },
          { model: "Sales::OrderFacts", field: "customer_count", id: "customer_count" },
          { model: "Sales::OrderFacts", field: "order_count", id: "order_count" },
          { model: "Sales::OrderFacts", field: "total_price", operator: "average", id: "average_order_value" },
          { model: "Sales::OrderFacts", field: "orders_per_customer", id: "average_order_value" }
        ],
        dimensions: []
      }
    },
    {
      type: "table_block",
      title: "Annual Summary",
      query: {
        measures: [
          { model: "Sales::OrderFacts", field: "total_price", operator: "sum", id: "total_price" },
          { model: "Sales::OrderFacts", field: "customer_count", id: "customer_count" },
          { model: "Sales::OrderFacts", field: "order_count", id: "order_count" },
          { model: "Sales::OrderFacts", field: "total_price", operator: "average", id: "average_order_value" },
          { model: "Sales::OrderFacts", field: "orders_per_customer", id: "average_order_value" }
        ],
        dimensions: [{ model: "Sales::OrderFacts", field: "created_at", operator: "date_trunc_year", id: "date" }]
      }
    },
    {
      type: "viz_block",
      title: "Pareto Analysis",
      query: {
        measures: [
          { model: "Sales::CustomerParetoFacts", field: "sales", id: "sales" },
          { model: "Sales::CustomerParetoFacts", field: "cumulative_percent_of_sales", id: "cumulative_percent_of_sales" },
          { model: "Sales::CustomerParetoFacts", field: "customer_rank", id: "customer_rank" }
        ],
        dimensions: [],
        orderings: [{ id: "customer_rank", direction: "asc" }],
        filters: [
          { field: { model: "Sales::CustomerParetoFacts", field: "year", id: "year" }, operator: "equals", values: [2019] },
          {
            field: { model: "Sales::CustomerParetoFacts", field: "business_line", id: "business_line" },
            operator: "equals",
            values: ["Direct to Consumer"]
          }
        ]
      },
      viz: {
        type: "viz",
        globalXId: "customer_rank",
        systems: [
          {
            type: "viz_system",
            vizType: "bar",
            xId: "customer_rank",
            yId: "sales"
          },
          {
            type: "viz_system",
            vizType: "line",
            xId: "customer_rank",
            yId: "cumulative_percent_of_sales"
          }
        ]
      }
    },
    {
      type: "viz_block",
      title: "Order Repurchase Intervals",
      query: {
        measures: [{ model: "Sales::RepurchaseIntervalFacts", field: "count", id: "count" }],
        dimensions: [
          { model: "Sales::RepurchaseIntervalFacts", field: "days_since_previous_order_bucket_label", id: "days_since_previous_order" }
        ]
      },
      viz: {
        type: "viz",
        systems: [
          {
            type: "viz_system",
            vizType: "bar",
            xId: "days_since_previous_order",
            yId: "count"
          }
        ]
      }
    }
  ]
};

const Component = new VizDocumentCompiler().compile(document);

export default class OrdersReviewReport extends Page {
  render() {
    return (
      <Page.Layout title="Orders Review">
        <Component />
      </Page.Layout>
    );
  }
}
