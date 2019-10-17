import { WarehouseIntrospectionMeasureField, WarehouseIntrospectionDimensionField } from "app/app-graph";
import { WarehouseIntrospectionForWarehouseFragment } from "app/app-graph";
import gql from "graphql-tag";

gql`
  fragment WarehouseIntrospectionForWarehouse on AppQuery {
    warehouseIntrospection {
      factTables {
        name
        measureFields {
          fieldName
          fieldLabel
          dataType
          allowsOperators
          requiresOperators
          defaultOperator
        }
        dimensionFields {
          fieldName
          fieldLabel
          dataType
          allowsOperators
        }
      }
      operators {
        key
      }
    }
  }
`;

export type WarehouseIntrospection = WarehouseIntrospectionForWarehouseFragment["warehouseIntrospection"];

export class Warehouse {
  introspection: WarehouseIntrospection;
  factTables: WarehouseIntrospection["factTables"];
  allFieldsIndex: {
    [model: string]: {
      [field: string]: WarehouseIntrospectionMeasureField | WarehouseIntrospectionDimensionField;
    };
  };
  measuresIndex: {
    [model: string]: {
      [field: string]: WarehouseIntrospectionMeasureField;
    };
  };
  dimensionsIndex: {
    [model: string]: {
      [field: string]: WarehouseIntrospectionDimensionField;
    };
  };

  constructor(introspection: WarehouseIntrospection) {
    this.introspection = introspection;
    this.factTables = introspection.factTables;
    this.allFieldsIndex = {};
    this.measuresIndex = {};
    this.dimensionsIndex = {};
    introspection.factTables.forEach(table => {
      this.allFieldsIndex[table.name] = {};
      this.measuresIndex[table.name] = {};
      this.dimensionsIndex[table.name] = {};

      table.measureFields.forEach(field => {
        this.allFieldsIndex[table.name][field.fieldName] = field;
        this.measuresIndex[table.name][field.fieldName] = field;
      });
      table.dimensionFields.forEach(field => {
        this.allFieldsIndex[table.name][field.fieldName] = field;
        this.dimensionsIndex[table.name][field.fieldName] = field;
      });
    });
  }

  measure(model: string, field: string) {
    const fields = this.measuresIndex[model];
    if (fields) {
      return fields[field];
    }
  }

  dimension(model: string, field: string) {
    const fields = this.measuresIndex[model];
    if (fields) {
      return fields[field];
    }
  }

  field(model: string, field: string) {
    const fields = this.allFieldsIndex[model];
    if (fields) {
      return fields[field];
    }
  }
}
