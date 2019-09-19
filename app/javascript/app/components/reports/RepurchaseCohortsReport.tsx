import React from "react";
import { Page } from "../common";
import { Compiler, Document } from "app/components/superviz";

const document: Document = {
  type: "document",
  id: "orders_review",
  blocks: [
    { type: "markdown_block", markdown: "This report breaks down the long term health of each cohort of customers." },
    {
      type: "viz_block",
      query: {
        measures: [
          { model: "Sales::RepurchaseCohortFacts", field: "pct_active_customers", id: "pct_active_customers" },
          { model: "Sales::RepurchaseCohortFacts", field: "genesis_month", id: "genesis_month" },
          { model: "Sales::RepurchaseCohortFacts", field: "months_since_genesis", id: "months_since_genesis" }
        ],
        dimensions: []
      },
      viz: {
        type: "viz",
        globalXId: "customer_rank",
        systems: [
          {
            type: "viz_system",
            vizType: "cohorts",
            xId: "months_since_genesis",
            yId: "pct_active_customers",
            extra: {
              cohortId: "genesis_month"
            }
          }
        ]
      }
    }
  ]
};

const Component = new Compiler().compile(document);

export default class RepurchaseCohortsReport extends Page {
  render() {
    return (
      <Page.Layout title="Repurchase Cohort Analysis">
        <Component />
      </Page.Layout>
    );
  }
}