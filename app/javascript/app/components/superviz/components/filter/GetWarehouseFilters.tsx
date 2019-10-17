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
    currentAccount {
      id
      businessLines {
        id
        name
      }
    }
  }
`;

export interface FactTableFilterContext {
  modelFilterFields: {
    [name: string]: {
      [id: string]: { id: string; field: string };
    };
  };
  businessLines: {
    [id: string]: {
      id: string;
      name: string;
    };
  };
}

export const GetWarehouseFilters = (props: { children: (result: FactTableFilterContext) => React.ReactNode }) => (
  <SimpleQuery component={GetWarehouseGlobalFilterOptionsComponent} require={["warehouseIntrospection", "currentAccount"]}>
    {result => {
      const nameIndex = keyBy(result.warehouseIntrospection.factTables, "name");
      return props.children({
        modelFilterFields: mapValues(nameIndex, factTable => keyBy(factTable.globalFilterFields, "id")),
        businessLines: keyBy(result.currentAccount.businessLines, "id")
      });
    }}
  </SimpleQuery>
);
