import React from "react";
import { Markdown } from "grommet";
import { MarkdownBlock } from "../../schema";

export const MarkdownBlockEditor = (props: { block: MarkdownBlock; index: number }) => {
  return <Markdown>{props.block.markdown}</Markdown>;
};
