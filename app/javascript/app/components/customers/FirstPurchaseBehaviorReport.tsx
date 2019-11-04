import { ReportDocument } from "app/components/superviz";
import { FullReportPage } from "../common/FullReportPage";

const doc: ReportDocument = {
  type: "document",
  id: "first_purchase_behaviour",
  blocks: [
    {
      type: "viz_block",
      title: "First Purchases By Vendor",
      size: "large",
      query: {
        measures: [{ model: "Sales::OrderProductLineFacts", field: "quantity", operator: "sum", id: "total_units" }],
        dimensions: [{ model: "Sales::OrderProductLineFacts", field: "variant_product_vendor", id: "vendor" }],
        filters: [
          {
            field: { model: "Sales::OrderProductLineFacts", field: "order_seq_number", id: "order_seq_number" },
            operator: "equals",
            values: [1]
          }
        ],
        limit: 30
      },
      viz: {
        type: "viz",
        systems: [
          {
            type: "viz_system",
            vizType: "bar",
            xId: "vendor",
            yId: "total_units"
          }
        ]
      }
    },
    {
      type: "viz_block",
      title: "First Purchases By Type",
      size: "large",
      query: {
        measures: [{ model: "Sales::OrderProductLineFacts", field: "quantity", operator: "sum", id: "total_units" }],
        dimensions: [{ model: "Sales::OrderProductLineFacts", field: "variant_product_type", id: "type" }],
        filters: [
          {
            field: { model: "Sales::OrderProductLineFacts", field: "order_seq_number", id: "order_seq_number" },
            operator: "equals",
            values: [1]
          }
        ],
        limit: 30
      },
      viz: {
        type: "viz",
        systems: [
          {
            type: "viz_system",
            vizType: "bar",
            xId: "type",
            yId: "total_units"
          }
        ]
      }
    },
    {
      type: "viz_block",
      title: "First Purchase Vendor By 3 Month Previous Revenue and 3 Month Predicted Revenue",
      size: "large",
      query: {
        measures: [
          {
            model: "Sales::OrderProductLineFacts",
            field: "customer_previous_3_month_revenue",
            operator: "average",
            id: "previous_3_month_revenue"
          },
          {
            model: "Sales::OrderProductLineFacts",
            field: "customer_future_3_month_predicted_revenue",
            operator: "average",
            id: "future_3_month_predicted_revenue"
          }
        ],
        dimensions: [{ model: "Sales::OrderProductLineFacts", field: "variant_product_type", id: "vendor" }],
        filters: [
          {
            field: { model: "Sales::OrderProductLineFacts", field: "order_seq_number", id: "order_seq_number" },
            operator: "equals",
            values: [1]
          }
        ],
        limit: 30
      },
      viz: {
        type: "viz",
        systems: [
          {
            type: "viz_system",
            vizType: "bar",
            xId: "vendor",
            yId: "previous_3_month_revenue"
          },
          {
            type: "viz_system",
            vizType: "bar",
            xId: "vendor",
            yId: "future_3_month_predicted_revenue"
          }
        ]
      }
    },
    {
      type: "viz_block",
      title: "First Purchase Type By 3 Month Previous Revenue and 3 Month Predicted Revenue",
      size: "large",
      query: {
        measures: [
          {
            model: "Sales::OrderProductLineFacts",
            field: "customer_previous_3_month_revenue",
            operator: "average",
            id: "previous_3_month_revenue"
          },
          {
            model: "Sales::OrderProductLineFacts",
            field: "customer_future_3_month_predicted_revenue",
            operator: "average",
            id: "future_3_month_predicted_revenue"
          }
        ],
        dimensions: [{ model: "Sales::OrderProductLineFacts", field: "variant_product_type", id: "type" }],
        filters: [
          {
            field: { model: "Sales::OrderProductLineFacts", field: "order_seq_number", id: "order_seq_number" },
            operator: "equals",
            values: [1]
          }
        ]
      },
      viz: {
        type: "viz",
        systems: [
          {
            type: "viz_system",
            vizType: "bar",
            xId: "type",
            yId: "previous_3_month_revenue"
          },
          {
            type: "viz_system",
            vizType: "bar",
            xId: "type",
            yId: "future_3_month_predicted_revenue"
          }
        ]
      }
    }
  ]
};

export default FullReportPage("First Purchase Behaviour", doc);
