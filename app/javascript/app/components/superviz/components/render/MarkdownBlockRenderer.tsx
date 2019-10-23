import React from "react";
import { Box, Markdown } from "grommet";
import styled from "styled-components";
import { MarkdownBlock } from "../../schema";

export const StyledMarkdownBlockContainer = styled.div`
  @media print {
    page-break-inside: avoid;
  }
`;

export const MarkdownBlockRenderer = (props: { block: MarkdownBlock }) => {
  return (
    <StyledMarkdownBlockContainer>
      <Markdown>{props.block.markdown}</Markdown>
    </StyledMarkdownBlockContainer>
  );
};
