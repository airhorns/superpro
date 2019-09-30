import { ReportDocument } from "app/components/superviz";
import { FullReportPage } from "../common/FullReportPage";

const doc: ReportDocument = {
  type: "document",
  id: "micro_order_timing",
  blocks: [
    {
      type: "viz_block",
      title: "Orders by Day of Week",
      query: {
        measures: [
          { model: "Sales::OrderFacts", field: "total_price", operator: "sum", id: "total_price" },
          { model: "Sales::OrderFacts", field: "count", id: "count" }
        ],
        dimensions: [{ model: "Sales::OrderFacts", field: "created_at", operator: "date_part_day_of_week", id: "day" }]
      },
      viz: {
        type: "viz",
        systems: [
          {
            type: "viz_system",
            vizType: "bar",
            xId: "day",
            yId: "total_price"
          },
          {
            type: "viz_system",
            vizType: "bar",
            xId: "day",
            yId: "count"
          }
        ]
      }
    },
    {
      type: "viz_block",
      title: "Orders by Hour of Day",
      query: {
        measures: [
          { model: "Sales::OrderFacts", field: "total_price", operator: "sum", id: "total_price" },
          { model: "Sales::OrderFacts", field: "count", id: "count" }
        ],
        dimensions: [{ model: "Sales::OrderFacts", field: "created_at", operator: "date_part_hour", id: "hour" }]
      },
      viz: {
        type: "viz",
        systems: [
          {
            type: "viz_system",
            vizType: "bar",
            xId: "hour",
            yId: "total_price"
          },
          {
            type: "viz_system",
            vizType: "bar",
            xId: "hour",
            yId: "count"
          }
        ]
      }
    }
  ]
};

export default FullReportPage("Micro Order Timing", doc);
