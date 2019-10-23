import React from "react";
import gql from "graphql-tag";
import { DateTime } from "luxon";
import { keyBy, groupBy, isFunction } from "lodash";
import {
  WarehouseQueryComponent,
  WarehouseQueryResult,
  WarehouseOutputIntrospectionMeasure,
  WarehouseOutputIntrospectionDimension,
  WarehouseQueryQueryVariables
} from "app/app-graph";
import { assert, Alert, SimpleQuery } from "superlib";
import { WarehouseQuery } from "../WarehouseQuery";
import { WarehousePivot } from "../pivot";
import { FormatterFns, formattersForOutput } from "./render/Formatters";
import { GetWarehouseFilters } from "./filter/GetWarehouseFilters";
import { GlobalFilterController } from "./filter/GlobalFilterController";
import { applyGlobalFilters } from "./filter/applyGlobalFilters";
import { isUndefined } from "util";

gql`
  query WarehouseQuery($query: JSONScalar!, $pivot: JSONScalar) {
    warehouseQuery(query: $query, pivot: $pivot) {
      records
      outputIntrospection {
        measures {
          id
          dataType
          operator
          label
          sortable
          pivotGroupId
        }
        pivotedMeasures {
          id
          dataType
          operator
          label
          sortable
          pivotGroupId
        }
        dimensions {
          id
          dataType
          operator
          label
          sortable
        }
      }
      errors
    }
  }
`;

export interface OutputIntrospection extends Exclude<WarehouseQueryResult["outputIntrospection"], null | undefined> {
  fields: (WarehouseOutputIntrospectionMeasure | WarehouseOutputIntrospectionDimension)[];
  fieldsById: { [id: string]: WarehouseOutputIntrospectionMeasure | WarehouseOutputIntrospectionDimension };
  measuresById: { [id: string]: WarehouseOutputIntrospectionMeasure };
  measuresByPivotGroupId: { [id: string]: WarehouseOutputIntrospectionMeasure[] };
  pivotedMeasuresById: { [id: string]: WarehouseOutputIntrospectionMeasure };
  dimensionsById: { [id: string]: WarehouseOutputIntrospectionDimension };
}

export interface SuccessfulWarehouseQueryResult {
  outputIntrospection: OutputIntrospection;
  formatters: FormatterFns;
  records: Exclude<WarehouseQueryResult["records"], null | undefined>;
}

export const VizQueryContext = React.createContext<SuccessfulWarehouseQueryResult>(null as any);

// Parse any incoming rich datatypes into a rich object for downstream consumption
const hydrate = (records: any[], outputIntrospection: SuccessfulWarehouseQueryResult["outputIntrospection"]) => {
  return records.map(record => {
    record = Object.assign({}, record);
    for (const field of outputIntrospection.fields) {
      if (!isUndefined(record[field.id])) {
        if (field.dataType == "DateTime") {
          record[field.id] = DateTime.fromISO(record[field.id]).toJSDate();
        } else if (field.dataType == "Percentage") {
          record[field.id] = parseFloat(record[field.id]);
        }
      }
    }

    return record;
  });
};

export const GetWarehouseData = (props: {
  query: WarehouseQuery;
  pivot?: WarehousePivot;
  children: React.ReactNode | ((result: SuccessfulWarehouseQueryResult) => React.ReactNode);
}) => (
  <GlobalFilterController.Consumer>
    {filterController => (
      <GetWarehouseFilters>
        {warehouseFilters => {
          const variables: WarehouseQueryQueryVariables = { query: props.query };
          if (props.pivot) {
            variables.pivot = props.pivot;
          }

          if (filterController.state.filters) {
            variables.query = applyGlobalFilters(variables.query, warehouseFilters, filterController);
          }

          return (
            <SimpleQuery
              component={WarehouseQueryComponent}
              require={["warehouseQuery"]}
              variables={variables}
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

                const rawOutputIntrospection = assert(data.warehouseQuery.outputIntrospection);
                const fields = (rawOutputIntrospection.measures as (
                  | WarehouseOutputIntrospectionMeasure
                  | WarehouseOutputIntrospectionDimension)[]).concat(rawOutputIntrospection.dimensions);

                const outputIntrospection: SuccessfulWarehouseQueryResult["outputIntrospection"] = Object.assign(
                  {},
                  rawOutputIntrospection,
                  {
                    fields: fields,
                    fieldsById: keyBy(fields, "id"),
                    measuresById: keyBy(rawOutputIntrospection.measures, "id"),
                    measuresByPivotGroupId: groupBy(rawOutputIntrospection.measures, "pivotGroupId"),
                    pivotedMeasuresById: keyBy(rawOutputIntrospection.pivotedMeasures, "id"),
                    dimensionsById: keyBy(rawOutputIntrospection.dimensions, "id")
                  }
                );

                const result: SuccessfulWarehouseQueryResult = {
                  outputIntrospection,
                  records: hydrate(data.warehouseQuery.records, outputIntrospection),
                  formatters: formattersForOutput(outputIntrospection)
                };

                return (
                  <VizQueryContext.Provider value={result}>
                    {isFunction(props.children) ? props.children(result) : props.children}
                  </VizQueryContext.Provider>
                );
              }}
            </SimpleQuery>
          );
        }}
      </GetWarehouseFilters>
    )}
  </GlobalFilterController.Consumer>
);
