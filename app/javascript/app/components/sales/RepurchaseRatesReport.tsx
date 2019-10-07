import { FullReportPage } from "../common/FullReportPage";

export default FullReportPage("Repurchase Rates", {
  type: "document",
  id: "orders_review",
  blocks: [
    { type: "markdown_block", markdown: "This report describes how many people return to repurchase over time." },
    {
      type: "viz_block",
      query: {
        measures: [{ model: "Sales::RepurchaseIntervalFacts", field: "early_repurchase_rate", id: "early_repurchase_rate" }],
        dimensions: [{ model: "Sales::RepurchaseIntervalFacts", field: "order_date", operator: "date_trunc_week", id: "date" }]
      },
      viz: {
        type: "viz",
        globalXId: "date",
        systems: [
          {
            type: "viz_system",
            vizType: "line",
            yId: "early_repurchase_rate",
            xId: "date"
          }
        ]
      }
    },
    {
      type: "viz_block",
      query: {
        measures: [{ model: "Sales::RepurchaseIntervalFacts", field: "overall_repurchase_rate", id: "overall_repurchase_rate" }],
        dimensions: [{ model: "Sales::RepurchaseIntervalFacts", field: "order_date", operator: "date_trunc_week", id: "date" }]
      },
      viz: {
        type: "viz",
        globalXId: "date",
        systems: [
          {
            type: "viz_system",
            vizType: "line",
            yId: "overall_repurchase_rate",
            xId: "date"
          }
        ]
      }
    },
    {
      type: "viz_block",
      query: {
        measures: [
          { model: "Sales::RepurchaseCohortFacts", field: "pct_active_customers", id: "pct_active_customers" },
          { model: "Sales::RepurchaseCohortFacts", field: "genesis_month", id: "genesis_month" },
          { model: "Sales::RepurchaseCohortFacts", field: "months_since_genesis", id: "months_since_genesis" }
        ],
        dimensions: [],
        orderings: [{ id: "genesis_month", direction: "asc" }]
      },
      viz: {
        type: "viz",
        globalXId: "customer_rank",
        systems: [
          {
            type: "viz_system",
            vizType: "cohorts",
            xId: "months_since_genesis",
            yId: "pct_active_customers",
            extra: {
              cohortId: "genesis_month"
            }
          }
        ]
      }
    }
  ]
});
