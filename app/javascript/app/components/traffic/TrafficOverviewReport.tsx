import { FullReportPage } from "../common/FullReportPage";
import { DateTime } from "luxon";

export default FullReportPage("Traffic Overview", {
  type: "document",
  id: "traffic_overview",
  blocks: [
    {
      type: "viz_block",
      title: "30 Day Visitors",
      query: {
        measures: [{ model: "Traffic::SessionFacts", field: "count", id: "sessions" }],
        dimensions: [{ model: "Traffic::SessionFacts", field: "session_start", operator: "date_trunc_day", id: "date" }],
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
            yId: "sessions"
          }
        ]
      }
    },
    {
      type: "viz_block",
      title: "30 Day Bounce Rate",
      query: {
        measures: [{ model: "Traffic::PageViewFacts", field: "bounce_pct", id: "bounce_rate" }],
        dimensions: [{ model: "Traffic::PageViewFacts", field: "min_tstamp", operator: "date_trunc_day", id: "date" }],
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
            yId: "bounce_rate"
          }
        ]
      }
    }
  ]
});
