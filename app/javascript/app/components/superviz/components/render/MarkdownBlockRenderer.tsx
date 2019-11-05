import React from "react";
import { Markdown, TextArea, Box } from "grommet";
import styled from "styled-components";
import { MarkdownBlock } from "../../schema";
import { SimpleModal } from "superlib";
import queryString from "query-string";
import useReactRouter from "use-react-router";

export const StyledMarkdownBlockContainer = styled.div`
  @media print {
    page-break-inside: avoid;
  }
`;

export const HackyMarkdownEditor = (props: { block: MarkdownBlock }) => {
  const { location } = useReactRouter();
  const params = queryString.parse(location.search);
  const editable = !!params.edit;

  const [value, setValue] = React.useState(props.block.markdown);
  return (
    <SimpleModal trigger={setShow => <Markdown onClick={() => editable && setShow(true)}>{value}</Markdown>}>
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
