import { SuperFormController, SuperFormChangeCallback } from "superlib/superform";
import { ReportDocument, Block, isQueryBlock, VizSystem } from "./schema";
import shortid from "shortid";
import { assert } from "superlib";
import { find, remove, findIndex } from "lodash";
import { Warehouse } from "./Warehouse";
import { Measure, Dimension } from "./WarehouseQuery";

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

  factTablesQueriedForBlockIndex(blockIndex: number) {
    const block = this.getQueryBlock(this.doc, blockIndex);
    return block.query.measures.map(measure => measure.model);
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
      const block = this.getQueryBlock(doc, blockIndex);
      const id = shortid.generate();
      const measureFieldIntrospection = assert(this.warehouse.measure(model, field));
      const measure: Measure = { id, model, field };
      if (measureFieldIntrospection.requiresOperators) {
        measure.operator = assert(measureFieldIntrospection.defaultOperator);
      }
      block.query.measures.push(measure);

      this.convergeViz(doc, blockIndex);
    });
  }

  addDimension(blockIndex: number, model: string, field: string, operator?: Dimension["operator"]) {
    this.dispatch((doc: ReportDocument) => {
      const block = this.getQueryBlock(doc, blockIndex);
      const id = shortid.generate();
      const dimension: Dimension = { id, model, field, operator };
      block.query.dimensions.push(dimension);

      this.convergeViz(doc, blockIndex);
    });
  }

  setMeasureField(blockIndex: number, measureId: string, model: string, field: string) {
    this.dispatch((doc: ReportDocument) => {
      const block = this.getQueryBlock(doc, blockIndex);

      const measure = assert(find(block.query.measures, { id: measureId }));
      measure.model = model;
      measure.field = field;
      this.convergeViz(doc, blockIndex);
    });
  }

  setDimensionField(blockIndex: number, dimensionId: string, model: string, field: string) {
    this.dispatch((doc: ReportDocument) => {
      const block = this.getQueryBlock(doc, blockIndex);

      const dimension = assert(find(block.query.dimensions, { id: dimensionId }));
      dimension.model = model;
      dimension.field = field;
      this.convergeViz(doc, blockIndex);
    });
  }

  setDimensionOperator(blockIndex: number, dimensionId: string, operator?: Dimension["operator"] | null) {
    this.dispatch((doc: ReportDocument) => {
      const block = this.getQueryBlock(doc, blockIndex);
      const dimension = assert(find(block.query.dimensions, { id: dimensionId }));
      if (operator) {
        dimension.operator = operator;
      } else {
        delete dimension.operator;
      }
      this.convergeViz(doc, blockIndex);
    });
  }

  removeMeasureField(blockIndex: number, measureId: string) {
    this.dispatch((doc: ReportDocument) => {
      const block = this.getQueryBlock(doc, blockIndex);
      const index = findIndex(block.query.measures, measure => measure.id == measureId);
      block.query.measures.splice(index, 1);
      this.convergeViz(doc, blockIndex);
    });
  }

  removeDimensionField(blockIndex: number, dimensionId: string) {
    this.dispatch((doc: ReportDocument) => {
      const block = this.getQueryBlock(doc, blockIndex);
      const index = findIndex(block.query.dimensions, dimension => dimension.id == dimensionId);
      block.query.dimensions.splice(index, 1);
      this.convergeViz(doc, blockIndex);
    });
  }

  private getQueryBlock(doc: ReportDocument, blockIndex: number) {
    const block = assert(doc.blocks[blockIndex]);
    if (!isQueryBlock(block)) {
      throw "Can't change the measures or dimensions of a block that doesn't make a query";
    }
    return block;
  }

  private convergeViz(doc: ReportDocument, blockIndex: number) {
    const block = assert(doc.blocks[blockIndex]);
    if (block.type !== "viz_block") {
      return;
    }

    block.viz = {
      type: "viz",
      systems: []
    };

    const preferredXAxisDimension =
      find(
        block.query.dimensions,
        dimension => assert(this.warehouse.dimension(dimension.model, dimension.field)).dataType == "DateTime"
      ) || block.query.dimensions[0];

    const segmentIds = block.query.dimensions
      .filter(dimension => dimension.id != preferredXAxisDimension.id)
      .map(dimension => dimension.id);

    block.query.measures.forEach(measure => {
      const system: VizSystem = {
        type: "viz_system",
        vizType: "line",
        yId: measure.id
      };

      if (segmentIds.length > 0) {
        system.segmentIds = segmentIds;
      }

      if (preferredXAxisDimension) {
        system.xId = preferredXAxisDimension.id;
      }

      block.viz.systems.push(system);
    });

    // if (preferredXAxisDimension) {
    //   block.viz.globalXId = preferredXAxisDimension.id;
    // }
  }
}
