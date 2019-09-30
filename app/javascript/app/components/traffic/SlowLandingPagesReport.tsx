import { FullReportPage } from "../common/FullReportPage";
import { ReportDocument } from "../superviz";

const document: ReportDocument = {
  type: "document",
  id: "slow_landing_pages",
  blocks: [
    {
      type: "table_block",
      title: "Slow Landing Pages",
      query: {
        measures: [
          { model: "Traffic::PageViewFacts", field: "count", id: "visit_count" },
          { model: "Traffic::PageViewFacts", field: "total_time_in_ms", operator: "average", id: "average_load_time" },
          { model: "Traffic::PageViewFacts", field: "total_time_in_ms", operator: "p90", id: "p90_load_time" },
          {
            model: "Traffic::PageViewFacts",
            field: "dom_loading_to_interactive_time_in_ms",
            operator: "average",
            id: "average_render_time"
          },
          { model: "Traffic::PageViewFacts", field: "dom_loading_to_interactive_time_in_ms", operator: "p90", id: "p90_render_time" }
        ],
        dimensions: [{ model: "Traffic::PageViewFacts", field: "page_url_path", id: "path" }],
        filters: [
          {
            field: {
              model: "Traffic::PageViewFacts",
              field: "page_view_in_session_index",
              id: "whatever"
            },
            operator: "equals",
            values: [1]
          },
          {
            field: {
              model: "Traffic::PageViewFacts",
              field: "ecommerce_function",
              id: "whatever2"
            },
            operator: "equals",
            values: ["Browsing"]
          },
          {
            field: {
              model: "Traffic::PageViewFacts",
              field: "total_time_in_ms",
              id: "whatever3"
            },
            operator: "is_not_null"
          }
        ],
        orderings: [
          {
            id: "average_load_time",
            direction: "desc"
          }
        ]
      }
    }
  ]
};

export default FullReportPage("Slow Landing Pages", document);
