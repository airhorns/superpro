import { WarehouseQuery } from "./WarehouseQuery";

export interface Document {
  type: "document";
  id: string;
  blocks: Block[];
}

export type Block = MarkdownBlock | TableBlock | VizBlock;

export interface MarkdownBlock {
  type: "markdown_block";
  markdown: string;
}

export interface TableBlock {
  type: "table_block";
  query: WarehouseQuery;
  title?: string;
}

export interface VizBlock {
  type: "viz_block";
  title?: string;
  query: WarehouseQuery;
  viz: Viz;
}

export interface Viz {
  type: "viz";
  systems: VizSystem[];
  globalSync?: boolean;
  showLegend?: boolean;
  showTooltip?: boolean;
  globalXId?: string;
}

export interface VizSystem {
  type: "viz_system";
  vizType: VizType;
  xId: string;
  yId: string;
  contextMarkdown?: string;
}

export type VizType = "bar" | "line" | "scatter";
