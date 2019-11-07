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
  "__schema": {
    "types": [
      {
        "kind": "UNION",
        "name": "ConnectionIntegrationUnion",
        "possibleTypes": [
          {
            "name": "PlaidItem"
          },
          {
            "name": "ShopifyShop"
          },
          {
            "name": "GoogleAnalyticsCredential"
          },
          {
            "name": "FacebookAdAccount"
          }
        ]
      }
    ]
  }
};
      export default result;
    