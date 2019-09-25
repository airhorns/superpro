import { FullReportPage } from "../common/FullReportPage";
import { DateTime } from "luxon";

export default FullReportPage("Sales Overview", {
  type: "document",
  id: "sales_overview",
  blocks: [
    {
      type: "viz_block",
      title: "30 Day Sales",
      query: {
        measures: [
          { model: "Sales::OrderFacts", field: "total_price", operator: "sum", id: "total_price" },
          { model: "Sales::OrderFacts", field: "customer_count", id: "customer_count" }
        ],
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
          },
          {
            type: "viz_system",
            vizType: "line",
            xId: "date",
            yId: "customer_count"
          }
        ]
      }
    }
  ]
});
