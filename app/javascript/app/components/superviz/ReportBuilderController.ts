import { SuperFormController, SuperFormChangeCallback } from "superlib/superform";
import { ReportDocument, Block, isQueryBlock, VizSystem } from "./schema";
import shortid from "shortid";
import { assert } from "superlib";
import { find } from "lodash";
import { Warehouse } from "./Warehouse";
import { Measure } from "./WarehouseQuery";

export class ReportBuilderController extends SuperFormController<ReportDocument> {
  warehouse: Warehouse;

  constructor(initialDoc: ReportDocument, onChange: SuperFormChangeCallback<ReportDocument>, warehouse: Warehouse) {
    super(initialDoc, onChange);
    this.warehouse = warehouse;
  }

  defaultBlockForType<T extends Block>(type: T["type"]): T {
    if (type == "viz_block") {
      return ({ type: "viz_block", query: { measures: [], dimensions: [] }, viz: { type: "viz", systems: [] } } as unknown) as T;
    } else if (type == "table_block") {
      return ({ type: "table_block", query: { measures: [], dimensions: [] } } as unknown) as T;
    } else {
      throw `Unknown block type ${type}`;
    }
  }

  appendBlock<T extends Block>(type: T["type"], attrs?: T) {
    let block: T;
    if (attrs) {
      block = attrs;
    } else {
      block = this.defaultBlockForType(type);
    }

    this.arrayHelpers("blocks").push(block);
  }

  addMeasure(blockIndex: number, model: string, field: string) {
    this.dispatch((doc: ReportDocument) => {
      const block = assert(doc.blocks[blockIndex]);
      if (!isQueryBlock(block)) {
        throw "Can't change the measures of a block that doesn't make a query";
      }
      const id = shortid.generate();
      const measureFieldIntrospection = assert(this.warehouse.measure(model, field));
      const measure: Measure = { id, model, field };
      if (measureFieldIntrospection.requiresOperators) {
        measure.operator = measureFieldIntrospection.defaultOperator;
      }
      block.query.measures.push(measure);

      if (block.type == "viz_block") {
        let system: VizSystem = {
          type: "viz_system",
          vizType: "line",
          yId: id
        };

        if (block.query.dimensions.length > 0) {
          system.xId = block.query.dimensions[0].id;
        }

        block.viz.systems.push(system);
      }
    });
  }

  setMeasureField(blockIndex: number, measureId: string, model: string, field: string) {
    this.dispatch((doc: ReportDocument) => {
      const block = assert(doc.blocks[blockIndex]);
      if (!isQueryBlock(block)) {
        throw "Can't change the measures of a block that doesn't make a query";
      }

      const measure = assert(find(block.query.measures, { id: measureId }));
      measure.model = model;
      measure.field = field;
    });
  }
}