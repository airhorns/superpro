import React from "react";
import { Document, Block } from "./schema";
import { VizDocumentContainer } from "./components/VizDocumentContainer";
import { Markdown } from "grommet";
import { VizBlockRenderer } from "./components/VizBlockRenderer";
import { TableBlockRenderer } from "./components/TableBlockRenderer";

export class Compiler {
  compile(doc: Document): React.ComponentType<{}> {
    const blocks = doc.blocks.map((block, index) => this.compileBlock(doc, block, index));
    return () => <VizDocumentContainer>{blocks}</VizDocumentContainer>;
  }

  private compileBlock = (doc: Document, block: Block, index: number) => {
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
