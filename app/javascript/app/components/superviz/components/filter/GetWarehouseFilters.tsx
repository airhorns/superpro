import React from "react";
import gql from "graphql-tag";
import { SimpleQuery } from "superlib";
import { GetWarehouseGlobalFilterOptionsComponent } from "app/app-graph";
import { keyBy, mapValues } from "lodash";

gql`
  query GetWarehouseGlobalFilterOptions {
    warehouseIntrospection {
      factTables {
        name
        globalFilterFields {
          id
          field
        }
      }
      operators {
        key
      }
    }
  }
`;

export interface FactTableFilterFields {
  [name: string]: {
    [id: string]: { id: string; field: string };
  };
}

export const GetWarehouseFilters = (props: { children: (result: FactTableFilterFields) => React.ReactNode }) => (
  <SimpleQuery component={GetWarehouseGlobalFilterOptionsComponent} require={["warehouseIntrospection"]}>
    {result => {
      const nameIndex = keyBy(result.warehouseIntrospection.factTables, "name");
      const fieldIndex = mapValues(nameIndex, factTable => keyBy(factTable.globalFilterFields, "id"));
      return props.children(fieldIndex);
    }}
  </SimpleQuery>
);
