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
            field: "future_24_month_predicted_spend_bucket_label",
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
      title: "Average Predicted 3 Month Value by Source / Medium Of Customer's First Order",
      query: {
        measures: [
          {
            model: "Traffic::CustomerAcquisitionFacts",
            field: "future_3_month_predicted_spend",
            operator: "average",
            id: "average_future_3_month_revenue"
          }
        ],
        dimensions: [{ model: "Traffic::CustomerAcquisitionFacts", field: "landing_page_identifier", id: "identifier" }],
        orderings: [{ id: "average_future_3_month_revenue", direction: "desc" }],
        limit: 25
      },
      viz: {
        type: "viz",
        systems: [
          {
            type: "viz_system",
            vizType: "bar",
            xId: "identifier",
            yId: "average_future_3_month_revenue"
          }
        ]
      }
    },
    {
      type: "markdown_block",
      markdown: `The above report shows which campaigns are driving customers that have the highest predicted value over the next 3 months. The graph includes the top 25 campaigns by average 3 month value.`
    },
    {
      type: "viz_block",
      title: "Repurchase Rates by Source / Medium Of Customer's First Order",
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
        dimensions: [{ model: "Traffic::CustomerAcquisitionFacts", field: "landing_page_identifier", id: "identifier" }],
        orderings: [{ id: "early_repurchase_rate", direction: "desc" }],
        limit: 25
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
      markdown: `The above report shows the repurchase rates of customers acquired from a given source / medium -- both the Early Repurchase Rate, which is defined as customers who make a repeat purchase less than 60 days after their first purchase, and the Overall Repurchase Rate, which is defined as customers who ever make a repeat purchase. The graph includes the top 25 campaigns by Early Repurchase Rate. Campaigns driving customers who come back and repurchase are driving much higher value traffic, especially those with a high early repeat purchase rate, as early repurchases often indicate a customer who will end up being very high value.

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
        ],
        orderings: [{ id: "customer_equity", direction: "desc" }]
      }
    }
  ]
});
