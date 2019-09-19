import React from "react";
import gql from "graphql-tag";
import { SimpleQuery } from "superlib/SimpleQuery";
import { WarehouseQueryComponent, WarehouseQueryResult, WarehouseQueryIntrospection } from "app/app-graph";
import { Alert } from "superlib/Alert";
import { WarehouseQuery } from "../WarehouseQuery";
import { assert } from "superlib";
import { DateTime } from "luxon";

gql`
  query WarehouseQuery($query: JSONScalar!) {
    warehouseQuery(query: $query) {
      records
      queryIntrospection {
        types
        fields {
          id
          type
          label
          sortable
        }
      }
      errors
    }
  }
`;

export interface SuccessfulWarehouseQueryResult {
  queryIntrospection: Exclude<WarehouseQueryResult["queryIntrospection"], null | undefined>;
  records: Exclude<WarehouseQueryResult["records"], null | undefined>;
}

export const VizQueryContext = React.createContext<SuccessfulWarehouseQueryResult>(null as any);

// Parse any incoming rich datatypes into a rich object for downstream consumption
const hydrate = (records: any[], queryIntrospection: WarehouseQueryIntrospection) => {
  return records.map(record => {
    for (const [id, datatype] of Object.entries(queryIntrospection.types)) {
      if (datatype == "date_time") {
        record[id] = DateTime.fromISO(record[id]).toJSDate();
      }
    }

    return record;
  });
};

export const GetWarehouseData = (props: { query: WarehouseQuery; children: React.ReactNode }) => {
  return (
    <SimpleQuery component={WarehouseQueryComponent} require={["warehouseQuery"]} variables={{ query: props.query }}>
      {data => {
        if (!data.warehouseQuery.records) {
          return <Alert type="error" message="There was an error loading this data. Please try again." />;
        }

        const queryIntrospection = assert(data.warehouseQuery.queryIntrospection);
        const result: SuccessfulWarehouseQueryResult = {
          queryIntrospection,
          records: hydrate(data.warehouseQuery.records, queryIntrospection)
        };

        return <VizQueryContext.Provider value={result}>{props.children}</VizQueryContext.Provider>;
      }}
    </SimpleQuery>
  );
};
