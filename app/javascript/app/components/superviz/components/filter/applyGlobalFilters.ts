import { GlobalFilterController } from "./GlobalFilterController";
import { WarehouseQuery } from "../../WarehouseQuery";
import { FactTableFilterFields } from "./GetWarehouseFilters";
import { assert } from "superlib";

export const modelsReferencedInQuery = (query: WarehouseQuery) => {
  const models = new Set<string>();

  query.measures.forEach(measure => {
    models.add(measure.model);
  });

  return Array.from(models);
};

export const applyGlobalFilters = (
  query: WarehouseQuery,
  warehouseFilters: FactTableFilterFields,
  filterController: GlobalFilterController
) => {
  const models = modelsReferencedInQuery(query);
  query = Object.assign({}, query);
  if (!query.filters) {
    query.filters = [];
  }

  Object.entries(filterController.state.filters).forEach(([id, params]) => {
    models.forEach(model => {
      const globalFilterFieldsForModel = assert(warehouseFilters[model]);
      const fieldId = `global-${model}-${id}`;
      const operator = assert(params).operator;
      const values = assert(params).values;

      switch (id) {
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
