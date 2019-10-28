import { FullReportPage } from "../common/FullReportPage";

export default FullReportPage("Marketing Activity Customer Quality", {
  type: "document",
  id: "marketing_activity_customer_quality",
  blocks: [
    {
      type: "markdown_block",
      markdown: `
This report breaks down how current customers have been acquired based on what led them to make their first order. Using observations since a given customer has been acquired like that customer's ongoing order frequency and average order value, we're able to predict a future value of that customer assuming they continue to order in a similar pattern before eventually becoming lost.

_Note_: For all the numbers on this report, we're measuring how customers behaved when and after they were acquired, and then attributing that behaviour back to the marketing activity that drove the customer's first order. We use a last click attribution model for now until Superpro supports multitouch attribution.`
    },
    {
      type: "viz_block",
      title: "Customer Count by Lifetime Value Bucket",
      query: {
        measures: [
          {
            model: "Traffic::CustomerAcquisitionFacts",
            field: "count",
            id: "count"
          }
        ],
        dimensions: [
          {
            model: "Traffic::CustomerAcquisitionFacts",
            field: "future_24_month_predicted_revenue_bucket_label",
            id: "predicted_clv"
          }
        ],
        orderings: [{ id: "predicted_clv", direction: "asc" }]
      },
      viz: {
        type: "viz",
        systems: [
          {
            type: "viz_system",
            vizType: "bar",
            xId: "predicted_clv",
            yId: "count"
          }
        ]
      }
    },
    {
      type: "markdown_block",
      markdown: `Here's the count of current customers by how much Superpro predicts their future value to be. There is a vast majority of customers who's value is predicted to be under $1 or under $10, which makes sense, because most of the customers the business has sold to in the past have since stopped purchasing. They could be re-activated, but, this helps to validate that the predictions the model is making are reasonable. There is a significant number of customers who's predicted value is greater than this though, which is good!`
    },
    {
      type: "viz_block",
      title: "Average Previous and Predicted 3 Month Value by Source / Campaign Of Customer's First Order - Paid Campaigns",
      size: "large",
      query: {
        measures: [
          {
            model: "Traffic::CustomerAcquisitionFacts",
            field: "previous_3_month_revenue",
            operator: "average",
            id: "average_past_3_month_revenue"
          },
          {
            model: "Traffic::CustomerAcquisitionFacts",
            field: "future_3_month_predicted_revenue",
            operator: "average",
            id: "average_future_3_month_revenue"
          }
        ],
        dimensions: [{ model: "Traffic::CustomerAcquisitionFacts", field: "landing_page_source_campaign", id: "identifier" }],
        orderings: [{ id: "average_future_3_month_revenue", direction: "desc" }],
        filters: [
          {
            field: { model: "Traffic::CustomerAcquisitionFacts", field: "landing_page_source_category", id: "src" },
            operator: "equals",
            values: ["paid"]
          },
          {
            field: { model: "Traffic::CustomerAcquisitionFacts", field: "count", id: "count" },
            operator: "greater_than_or_equals",
            values: [3]
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
            xId: "identifier",
            yId: "average_future_3_month_revenue"
          },
          {
            type: "viz_system",
            vizType: "bar",
            xId: "identifier",
            yId: "average_past_3_month_revenue"
          }
        ]
      }
    },
    {
      type: "viz_block",
      title: "Average Previous and Predicted 3 Month Value by Source / Campaign Of Customer's First Order - Email Campaigns",
      size: "large",
      query: {
        measures: [
          {
            model: "Traffic::CustomerAcquisitionFacts",
            field: "future_3_month_predicted_revenue",
            operator: "average",
            id: "average_future_3_month_revenue"
          },
          {
            model: "Traffic::CustomerAcquisitionFacts",
            field: "previous_3_month_revenue",
            operator: "average",
            id: "average_past_3_month_revenue"
          }
        ],
        dimensions: [{ model: "Traffic::CustomerAcquisitionFacts", field: "landing_page_source_campaign", id: "identifier" }],
        orderings: [{ id: "average_future_3_month_revenue", direction: "desc" }],
        filters: [
          {
            field: { model: "Traffic::CustomerAcquisitionFacts", field: "landing_page_source_category", id: "src" },
            operator: "equals",
            values: ["email"]
          },
          {
            field: { model: "Traffic::CustomerAcquisitionFacts", field: "count", id: "count" },
            operator: "greater_than_or_equals",
            values: [3]
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
            xId: "identifier",
            yId: "average_future_3_month_revenue"
          },
          {
            type: "viz_system",
            vizType: "bar",
            xId: "identifier",
            yId: "average_past_3_month_revenue"
          }
        ]
      }
    },
    {
      type: "markdown_block",
      markdown: `The above two reports show which campaigns are driving customers that have the highest average predicted spend over the next 3 months compared to the average spend over the previous three months. There's two graphs one for paid & CPC campaigns, and one for email campaigns. Each graph includes the top 30 campaigns for that category that have driven at least 3 orders to reduce noise. We split paid and email out because email campaigns are often effective but yield less control over spend, whereas paid/CPC campaigns can have their budgets adjusted to aquire the most valuable customers possible. Campaigns on the left side of the graphs are predicted to drive higher value customers than campaigns on the right.

__Note__: Previous 3 month spend and future 3 month spend often don't line up perfectly for a variety of reasons usually owing to new campaigns, small sample size, campaign adjustments in the 3 month window, Superpro prediction inaccuracy, and confounding factors like discounts being present in some campaign's copy.`
    },
    {
      type: "viz_block",
      title: "Repurchase Rates by Source / Campaign Of Customer's First Order",
      size: "large",
      query: {
        measures: [
          {
            model: "Traffic::CustomerAcquisitionFacts",
            field: "early_repurchase_rate",
            id: "early_repurchase_rate"
          },
          {
            model: "Traffic::CustomerAcquisitionFacts",
            field: "overall_repurchase_rate",
            id: "overall_repurchase_rate"
          }
        ],
        dimensions: [{ model: "Traffic::CustomerAcquisitionFacts", field: "landing_page_source_campaign", id: "identifier" }],
        orderings: [{ id: "early_repurchase_rate", direction: "desc" }],
        filters: [
          {
            field: { model: "Traffic::CustomerAcquisitionFacts", field: "count", id: "count" },
            operator: "greater_than_or_equals",
            values: [3]
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
            xId: "identifier",
            yId: "early_repurchase_rate"
          },
          {
            type: "viz_system",
            vizType: "bar",
            xId: "identifier",
            yId: "overall_repurchase_rate"
          }
        ]
      }
    },
    {
      type: "markdown_block",
      markdown: `The above report shows the repurchase rates of customers acquired from a given source / campaign -- both the Early Repurchase Rate, which is defined as customers who make a repeat purchase less than 60 days after their first purchase, and the Overall Repurchase Rate, which is defined as customers who ever make a repeat purchase. The graph includes the top 30 campaigns by Early Repurchase Rate. Campaigns driving customers who come back and repurchase are driving much higher value traffic, especially those with a high early repeat purchase rate, as early repurchases often indicate a customer who will end up being very high value.

Below is the raw data powering this report for deeper investigation.`
    },
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
          { model: "Traffic::CustomerAcquisitionFacts", field: "total_revenue", operator: "sum", id: "total_revenue" },
          {
            model: "Traffic::CustomerAcquisitionFacts",
            field: "future_3_month_predicted_revenue",
            operator: "average",
            id: "average_future_3_month_predicted_revenue"
          },
          {
            model: "Traffic::CustomerAcquisitionFacts",
            field: "early_repurchase_rate",
            id: "early_repurchase_rate"
          },
          {
            model: "Traffic::CustomerAcquisitionFacts",
            field: "overall_repurchase_rate",
            id: "overall_repurchase_rate"
          }
        ],
        dimensions: [
          { model: "Traffic::CustomerAcquisitionFacts", field: "landing_page_utm_source", id: "utm_source" },
          { model: "Traffic::CustomerAcquisitionFacts", field: "landing_page_utm_campaign", id: "utm_campaign" }
        ],
        orderings: [{ id: "count", direction: "desc" }]
      }
    }
  ]
});
