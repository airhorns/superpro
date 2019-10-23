import React from "react";
import { uniq, flatMap } from "lodash";
import { assert } from "superlib";
import { ReportDocument, Block, isQueryBlock } from "./schema";
import { VizDocumentContainer } from "./components/render/VizDocumentContainer";
import { MarkdownBlockRenderer } from "./components/render/MarkdownBlockRenderer";
import { VizBlockRenderer } from "./components/render/VizBlockRenderer";
import { TableBlockRenderer } from "./components/render/TableBlockRenderer";
import { FactTableFilterContext } from "./components/filter/GetWarehouseFilters";
import { GlobalFilterControls } from "./components/filter/GlobalFilterControls";

export class VizDocumentCompiler {
  filtersContext: FactTableFilterContext;
  doc: ReportDocument;

  constructor(filtersContext: FactTableFilterContext, doc: ReportDocument) {
    this.filtersContext = filtersContext;
    this.doc = doc;
  }

  compileReport(): React.ComponentType<{}> {
    const blocks = this.doc.blocks.map((block, index) => this.compileBlock(block, index));
    return () => <VizDocumentContainer>{blocks}</VizDocumentContainer>;
  }

  compileFilterControls(): React.ComponentType<{}> {
    const filters = this.globalFilterSet();
    return () => <GlobalFilterControls enabledFilters={filters} filtersContext={this.filtersContext} />;
  }

  private compileBlock(block: Block, index: number) {
    if (block.type == "markdown_block") {
      return <MarkdownBlockRenderer key={index} block={block} />;
    } else if (block.type == "viz_block") {
      return <VizBlockRenderer key={index} doc={this.doc} block={block} />;
    } else if (block.type == "table_block") {
      return <TableBlockRenderer key={index} doc={this.doc} block={block} />;
    } else {
      throw `Unknown viz document block type ${(block as any).type}`;
    }
  }

  private globalFilterSet() {
    const filterModels = new Set<string>();

    this.doc.blocks.forEach(block => {
      if (isQueryBlock(block)) {
        block.query.measures.forEach(measure => {
          filterModels.add(measure.model);
        });
      }
    });

    return uniq(flatMap(Array.from(filterModels), modelName => Object.keys(assert(this.filtersContext.modelFilterFields[modelName]))));
  }
}
