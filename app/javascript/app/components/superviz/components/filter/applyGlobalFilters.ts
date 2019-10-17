import { GlobalFilterController } from "./GlobalFilterController";
import { WarehouseQuery } from "../../WarehouseQuery";
import { FactTableFilterContext } from "./GetWarehouseFilters";
import { assert } from "superlib";
import { DateTime, Duration } from "luxon";

export const modelsReferencedInQuery = (query: WarehouseQuery) => {
  const models = new Set<string>();

  query.measures.forEach(measure => {
    models.add(measure.model);
  });

  return Array.from(models);
};

export const applyGlobalFilters = (
  query: WarehouseQuery,
  filtersContext: FactTableFilterContext,
  filterController: GlobalFilterController
) => {
  const models = modelsReferencedInQuery(query);
  query = Object.assign({}, query);
  if (!query.filters) {
    query.filters = [];
  }

  Object.entries(filterController.state.filters).forEach(([id, params]) => {
    models.forEach(model => {
      const globalFilterFieldsForModel = assert(filtersContext.modelFilterFields[model]);
      const fieldId = `global-${model}-${id}`;
      const operator = assert(params).operator;
      const values = assert(params).values;

      switch (id) {
        case "duration_key": {
          if (globalFilterFieldsForModel["date"]) {
            assert(query.filters).push({
              field: {
                id: fieldId,
                model,
                field: globalFilterFieldsForModel["date"].field
              },
              operator,
              values: [
                DateTime.local()
                  .plus(Duration.fromISO(assert(values)[0] as string))
                  .toISO()
              ]
            });
          }
          break;
        }
        case "end_date":
        case "start_date": {
          if (globalFilterFieldsForModel["date"]) {
            assert(query.filters).push({
              field: {
                id: fieldId,
                model,
                field: globalFilterFieldsForModel["date"].field
              },
              operator,
              values
            });
          }
          break;
        }
        default: {
          if (globalFilterFieldsForModel[id]) {
            assert(query.filters).push({
              field: {
                id: fieldId,
                model,
                field: globalFilterFieldsForModel[id].field
              },
              operator,
              values
            });
          }
        }
      }
    });
  });

  return query;
};
