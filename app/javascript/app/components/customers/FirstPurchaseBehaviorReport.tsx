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
      title: "3 Month Previous Revenue and 3 Month Predicted Revenue By First Purchase Vendor",
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
      title: "3 Month Previous Revenue and 3 Month Predicted Revenue By First Purchase Type",
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
    },
    {
      type: "viz_block",
      title: "Early Repurchase Rate and Overall Repurchase Rate By First Purchase Type",
      size: "large",
      query: {
        measures: [
          {
            model: "Sales::OrderProductLineFacts",
            field: "customer_early_repurchase_rate",
            id: "early_repurchase_rate"
          },
          {
            model: "Sales::OrderProductLineFacts",
            field: "customer_overall_repurchase_rate",
            id: "overall_repurchase_rate"
          }
        ],
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
            yId: "early_repurchase_rate"
          },
          {
            type: "viz_system",
            vizType: "bar",
            xId: "type",
            yId: "overall_repurchase_rate"
          }
        ]
      }
    },
    {
      type: "viz_block",
      title: "Early Repurchase Rate and Overall Repurchase Rate By First Purchase Vendor",
      size: "large",
      query: {
        measures: [
          {
            model: "Sales::OrderProductLineFacts",
            field: "customer_early_repurchase_rate",
            id: "early_repurchase_rate"
          },
          {
            model: "Sales::OrderProductLineFacts",
            field: "customer_overall_repurchase_rate",
            id: "overall_repurchase_rate"
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
            yId: "early_repurchase_rate"
          },
          {
            type: "viz_system",
            vizType: "bar",
            xId: "vendor",
            yId: "overall_repurchase_rate"
          }
        ]
      }
    },
    {
      type: "table_block",
      title: "First Sales Order and Customer Values By Individual Product",
      query: {
        measures: [
          { model: "Sales::OrderProductLineFacts", field: "count", id: "purchase_count" },
          { model: "Sales::OrderProductLineFacts", field: "quantity", operator: "average", id: "average_quantity" },
          {
            model: "Sales::OrderProductLineFacts",
            field: "customer_first_order_total_price",
            operator: "average",
            id: "average_first_order_value"
          },
          {
            model: "Sales::OrderProductLineFacts",
            field: "customer_first_3_month_revenue",
            operator: "average",
            id: "average_3_month_revenue"
          }
        ],
        dimensions: [
          { model: "Sales::OrderProductLineFacts", field: "variant_product_id", id: "id" },
          { model: "Sales::OrderProductLineFacts", field: "variant_product_title", id: "product_title" },
          { model: "Sales::OrderProductLineFacts", field: "variant_product_type", id: "product_type" },
          { model: "Sales::OrderProductLineFacts", field: "variant_product_vendor", id: "product_vendor" }
        ],
        orderings: [{ id: "purchase_count", direction: "desc" }],
        filters: [
          {
            field: { model: "Sales::OrderProductLineFacts", field: "order_seq_number", id: "order_seq_number" },
            operator: "equals",
            values: [1]
          }
        ]
      }
    }
  ]
};

export default FullReportPage("First Purchase Behaviour", doc);
