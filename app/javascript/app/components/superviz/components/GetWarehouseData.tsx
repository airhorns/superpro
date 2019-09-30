import React from "react";
import gql from "graphql-tag";
import { SimpleQuery } from "superlib/SimpleQuery";
import {
  WarehouseQueryComponent,
  WarehouseQueryResult,
  WarehouseQueryIntrospection,
  WarehouseQueryIntrospectionField
} from "app/app-graph";
import { Alert } from "superlib/Alert";
import { WarehouseQuery } from "../WarehouseQuery";
import { assert } from "superlib";
import { DateTime } from "luxon";
import { keyBy } from "lodash";

gql`
  query WarehouseQuery($query: JSONScalar!) {
    warehouseQuery(query: $query) {
      records
      queryIntrospection {
        fields {
          id
          dataType
          label
          sortable
        }
      }
      errors
    }
  }
`;

export interface SuccessfulWarehouseQueryResult {
  queryIntrospection: Exclude<WarehouseQueryResult["queryIntrospection"], null | undefined> & {
    fieldsById: { [id: string]: WarehouseQueryIntrospectionField };
  };
  records: Exclude<WarehouseQueryResult["records"], null | undefined>;
}

export const VizQueryContext = React.createContext<SuccessfulWarehouseQueryResult>(null as any);

// Parse any incoming rich datatypes into a rich object for downstream consumption
const hydrate = (records: any[], queryIntrospection: WarehouseQueryIntrospection) => {
  return records.map(record => {
    for (const field of queryIntrospection.fields) {
      if (field.dataType == "DateTime") {
        record[field.id] = DateTime.fromISO(record[field.id]);
      }
    }

    return record;
  });
};

export const GetWarehouseData = (props: { query: WarehouseQuery; children: React.ReactNode }) => {
  return (
    <SimpleQuery
      component={WarehouseQueryComponent}
      require={["warehouseQuery"]}
      variables={{ query: props.query }}
      context={{
        queryParams: {
          warehouseFields: props.query.measures
            .map(measure => measure.id)
            .concat(props.query.dimensions.map(measure => measure.id))
            .join("/")
        }
      }}
    >
      {data => {
        if (!data.warehouseQuery.records) {
          return <Alert type="error" message="There was an error loading this data. Please try again." />;
        }

        const returnedIntrospection = assert(data.warehouseQuery.queryIntrospection);

        const queryIntrospection: SuccessfulWarehouseQueryResult["queryIntrospection"] = Object.assign({}, returnedIntrospection, {
          fieldsById: keyBy(returnedIntrospection.fields, "id")
        });

        const result: SuccessfulWarehouseQueryResult = {
          queryIntrospection,
          records: hydrate(data.warehouseQuery.records, queryIntrospection)
        };

        return <VizQueryContext.Provider value={result}>{props.children}</VizQueryContext.Provider>;
      }}
    </SimpleQuery>
  );
};
