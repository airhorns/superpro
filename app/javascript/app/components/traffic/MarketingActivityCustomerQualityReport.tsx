import { FullReportPage } from "../common/FullReportPage";

export default FullReportPage("Marketing Activity Customer Quality", {
  type: "document",
  id: "marketing_activity_customer_quality",
  blocks: [
    { type: "markdown_block", markdown: "This report describes what kind of customers different marketing activities are aquiring." },
    {
      type: "table_block",
      query: {
        measures: [
          { model: "Traffic::CustomerAcquisitionFacts", field: "count", id: "count" },
          {
            model: "Traffic::CustomerAcquisitionFacts",
            field: "first_order_total_price",
            operator: "average",
            id: "average_first_order_price"
          },
          { model: "Traffic::CustomerAcquisitionFacts", field: "total_spend", operator: "sum", id: "total_revenue" },
          {
            model: "Traffic::CustomerAcquisitionFacts",
            field: "future_3_month_predicted_spend",
            operator: "average",
            id: "average_future_3_month_predicted_spend"
          },
          {
            model: "Traffic::CustomerAcquisitionFacts",
            field: "future_12_month_predicted_spend",
            operator: "average",
            id: "average_future_12_month_predicted_spend"
          },
          { model: "Traffic::CustomerAcquisitionFacts", field: "future_24_month_predicted_spend", operator: "sum", id: "customer_equity" }
        ],
        dimensions: [
          { model: "Traffic::CustomerAcquisitionFacts", field: "landing_page_utm_source", id: "utm_source" },
          { model: "Traffic::CustomerAcquisitionFacts", field: "landing_page_utm_medium", id: "utm_medium" }
        ]
      }
    }
  ]
});
