// THIS IS A GENERATED FILE! You shouldn't edit it manually. Regenerate it using yarn `generate-graphql`.

export interface IntrospectionResultData {
  __schema: {
    types: {
      kind: string;
      name: string;
      possibleTypes: {
        name: string;
      }[];
    }[];
  };
}

const result: IntrospectionResultData = {
  __schema: {
    types: [
      {
        kind: "UNION",
        name: "TodoFeedItemSourceUnion",
        possibleTypes: [
          {
            name: "ProcessExecution"
          },
          {
            name: "Scratchpad"
          }
        ]
      },
      {
        kind: "UNION",
        name: "BudgetLineValue",
        possibleTypes: [
          {
            name: "BudgetLineFixedValue"
          },
          {
            name: "BudgetLineSeriesValue"
          }
        ]
      },
      {
        kind: "UNION",
        name: "ConnectionIntegrationUnion",
        possibleTypes: [
          {
            name: "PlaidItem"
          }
        ]
      }
    ]
  }
};

export default result;
