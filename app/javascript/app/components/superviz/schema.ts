import { WarehouseQuery } from "./WarehouseQuery";
import { ArrayElementType } from "app/lib/types";

export interface ReportDocument {
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
  xId?: string;
  yId: string;
  contextMarkdown?: string;
  extra?: any;
}

export type VizType = "bar" | "line" | "scatter" | "cohorts";
export type BlockType = ArrayElementType<ReportDocument["blocks"]>["type"];

export const isQueryBlock = (block: Block): block is VizBlock | TableBlock => block.type == "viz_block" || block.type == "table_block";
