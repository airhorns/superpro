import React from "react";
import { ReportDocument, Block } from "./schema";
import { VizDocumentContainer } from "./components/render/VizDocumentContainer";
import { Markdown } from "grommet";
import { VizBlockRenderer } from "./components/render/VizBlockRenderer";
import { TableBlockRenderer } from "./components/render/TableBlockRenderer";

export class VizDocumentCompiler {
  compile(doc: ReportDocument): React.ComponentType<{}> {
    const blocks = doc.blocks.map((block, index) => this.compileBlock(doc, block, index));
    return () => <VizDocumentContainer>{blocks}</VizDocumentContainer>;
  }

  private compileBlock = (doc: ReportDocument, block: Block, index: number) => {
    if (block.type == "markdown_block") {
      return <Markdown key={index}>{block.markdown}</Markdown>;
    } else if (block.type == "viz_block") {
      return <VizBlockRenderer key={index} doc={doc} block={block} />;
    } else if (block.type == "table_block") {
      return <TableBlockRenderer key={index} doc={doc} block={block} />;
    } else {
      throw `Unknown viz document block type ${(block as any).type}`;
    }
  };
}
