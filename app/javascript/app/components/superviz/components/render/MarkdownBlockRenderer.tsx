import React from "react";
import { Markdown, TextArea, Box } from "grommet";
import styled from "styled-components";
import { MarkdownBlock } from "../../schema";
import { SimpleModal } from "superlib";

export const StyledMarkdownBlockContainer = styled.div`
  @media print {
    page-break-inside: avoid;
  }
`;

export const HackyMarkdownEditor = (props: { block: MarkdownBlock }) => {
  const [value, setValue] = React.useState(props.block.markdown);
  return (
    <SimpleModal trigger={setShow => <Markdown onClick={() => setShow(true)}>{value}</Markdown>}>
      <Box width="xlarge" height="xlarge">
        <TextArea fill value={value} onChange={(event: React.ChangeEvent<HTMLTextAreaElement>) => setValue(event.target.value)} />
      </Box>
    </SimpleModal>
  );
};

export const MarkdownBlockRenderer = (props: { block: MarkdownBlock }) => {
  return (
    <StyledMarkdownBlockContainer>
      <HackyMarkdownEditor block={props.block} />
    </StyledMarkdownBlockContainer>
  );
};
