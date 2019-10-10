import { FullReportPage } from "../common/FullReportPage";
import { DateTime } from "luxon";

export default FullReportPage("Sales Overview", {
  type: "document",
  id: "sales_overview",
  blocks: [
    {
      type: "viz_block",
      title: "Average Order Value",
      query: {
        measures: [{ model: "Sales::OrderFacts", field: "total_price", operator: "average", id: "total_price" }],
        dimensions: [{ model: "Sales::OrderFacts", field: "created_at", operator: "date_trunc_day", id: "date" }],
        filters: [
          {
            id: "date",
            operator: "greater_than",
            values: [
              DateTime.local()
                .minus({ days: 30 })
                .toISO()
            ]
          }
        ]
      },
      viz: {
        type: "viz",
        systems: [
          {
            type: "viz_system",
            vizType: "line",
            xId: "date",
            yId: "total_price"
          }
        ]
      }
    },
    {
      type: "viz_block",
      title: "New vs Returning Customers",
      query: {
        measures: [{ model: "Sales::OrderFacts", field: "unique_customer_count", id: "customer_count" }],
        dimensions: [
          { model: "Sales::OrderFacts", field: "created_at", operator: "date_trunc_day", id: "date" },
          { model: "Sales::OrderFacts", field: "new_vs_repeat", id: "new_vs_repeat" }
        ],
        filters: [
          {
            id: "date",
            operator: "greater_than",
            values: [
              DateTime.local()
                .minus({ days: 30 })
                .toISO()
            ]
          }
        ]
      },
      viz: {
        type: "viz",
        systems: [
          {
            type: "viz_system",
            vizType: "line",
            xId: "date",
            yId: "customer_count",
            segmentIds: ["new_vs_repeat"]
          }
        ]
      }
    },
    {
      type: "viz_block",
      title: "New vs Returning Revenue",
      query: {
        measures: [{ model: "Sales::OrderFacts", field: "total_price", operator: "sum", id: "sales" }],
        dimensions: [
          { model: "Sales::OrderFacts", field: "created_at", operator: "date_trunc_day", id: "date" },
          { model: "Sales::OrderFacts", field: "new_vs_repeat", id: "new_vs_repeat" }
        ],
        filters: [
          {
            id: "date",
            operator: "greater_than",
            values: [
              DateTime.local()
                .minus({ days: 30 })
                .toISO()
            ]
          }
        ]
      },
      viz: {
        type: "viz",
        systems: [
          {
            type: "viz_system",
            vizType: "line",
            xId: "date",
            yId: "sales",
            segmentIds: ["new_vs_repeat"]
          }
        ]
      }
    }
  ]
});
