import { FullReportPage } from "../common/FullReportPage";

export default FullReportPage("Repurchase Rates", {
  type: "document",
  id: "orders_review",
  blocks: [
    {
      type: "markdown_block",
      markdown: `This report describes the behavior of customers who return to purchase more than once. Below are two charts showing the Early Repurchase Rate and the Overall Repurchase Rate over time. Early Repurchases are defined as customers who make another purchase less than 60 days after the previous one, and the Overall Repurchase Rate counts any repeat purchase after any amount of time. Both graphs show the repurchase rates for the time of the *first* purchase, counting how many customers at that time went on to repurchase in the time window.

__Note__: Both repurchase rates trail down to 0 for the most recent time range. This is because not that much time has gone by since recent purchases, which means there are likely some customers who will repurchase (within 60 days or longer than that), it just hasn't happened yet.`
    },
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
      type: "markdown_block",
      markdown: `The graph below shows how common it is for a customer to repurchase at a given time interval by counting and bucketing the duration between all repeat purchases seen.`
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
    },
    {
      type: "markdown_block",
      markdown: `The heatmaps below show repeat purchase percentage and the total spend for customers who made their first purchase in a given month (the "genesis" month) over the next 12 months. This visualization shows how customers aquired in a given month go on to re-engage with the brand by repurchasing. Ideally, newer cohorts (lower on the heatmap) perform better by repurchasing more often and spending more by some month later. Diagonal patterns in the graph often represent big cohorts acquired around big events, like Black Friday or a big Q4.`
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
    },
    {
      type: "viz_block",
      query: {
        measures: [
          { model: "Sales::RepurchaseCohortFacts", field: "total_spend", id: "total_spend" },
          { model: "Sales::RepurchaseCohortFacts", field: "genesis_month", id: "genesis_month" },
          { model: "Sales::RepurchaseCohortFacts", field: "months_since_genesis", id: "months_since_genesis" }
        ],
        dimensions: [],
        orderings: [{ id: "genesis_month", direction: "asc" }]
      },
      viz: {
        type: "viz",
        systems: [
          {
            type: "viz_system",
            vizType: "cohorts",
            xId: "months_since_genesis",
            yId: "total_spend",
            extra: {
              cohortId: "genesis_month"
            }
          }
        ]
      }
    }
  ]
});
