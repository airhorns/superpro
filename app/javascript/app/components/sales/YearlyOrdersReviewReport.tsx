import { FullReportPage } from "../common/FullReportPage";

export default FullReportPage("Orders Review", {
  type: "document",
  id: "orders_review",
  blocks: [
    {
      type: "markdown_block",
      markdown:
        "This report breaks down the long term health of the business based on sales data from Shopify. Below is a lifetime summary and annual summary of core KPIs."
    },
    {
      type: "table_block",
      title: "Lifetime Summary",
      query: {
        measures: [
          { model: "Sales::OrderFacts", field: "total_price", operator: "sum", id: "total_price" },
          { model: "Sales::OrderFacts", field: "unique_customer_count", id: "customer_count" },
          { model: "Sales::OrderFacts", field: "order_count", id: "order_count" },
          { model: "Sales::OrderFacts", field: "total_price", operator: "average", id: "average_order_value" },
          { model: "Sales::OrderFacts", field: "orders_per_customer", id: "orders_per_customer" }
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
          { model: "Sales::OrderFacts", field: "unique_customer_count", id: "customer_count" },
          { model: "Sales::OrderFacts", field: "order_count", id: "order_count" },
          { model: "Sales::OrderFacts", field: "total_price", operator: "average", id: "average_order_value" },
          { model: "Sales::OrderFacts", field: "orders_per_customer", id: "orders_per_customer" }
        ],
        dimensions: [{ model: "Sales::OrderFacts", field: "created_at", operator: "date_trunc_year", id: "date" }]
      }
    },
    {
      type: "markdown_block",
      markdown: "A placeholder."
    },
    {
      type: "viz_block",
      title: "Customer Concentration - Pareto Analysis",
      query: {
        measures: [
          { model: "Sales::CustomerParetoFacts", field: "sales", id: "sales" },
          { model: "Sales::CustomerParetoFacts", field: "cumulative_percent_of_sales", id: "cumulative_percent_of_sales" },
          { model: "Sales::CustomerParetoFacts", field: "customer_rank", id: "customer_rank" }
        ],
        dimensions: [],
        orderings: [{ id: "customer_rank", direction: "asc" }],
        filters: [{ field: { model: "Sales::CustomerParetoFacts", field: "year", id: "year" }, operator: "equals", values: [2019] }]
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
      type: "markdown_block",
      markdown: `The above graph describes the variety and distribution of high value customers of the business. For a business making most of its revenue from a small group of high value customers, the sales fall off very fast from left to right, and the cumulative sales percentage ramps up very quickly. For a business with many more customers, the cumulative percentage ramps up much slower. The healthiest businesses have a diverse set of customers with a thick center portion of many good value customers, some high value customers, and a long tail of low value customers.`
    }
  ]
});
