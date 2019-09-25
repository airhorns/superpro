import { FullReportPage } from "../common/FullReportPage";

export default FullReportPage("Repurchase Cohort Analysis", {
  type: "document",
  id: "orders_review",
  blocks: [
    { type: "markdown_block", markdown: "This report breaks down the long term health of each cohort of customers." },
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
