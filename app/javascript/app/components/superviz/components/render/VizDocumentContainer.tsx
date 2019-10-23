import React from "react";
import { Box } from "grommet";
import styled from "styled-components";

export const StyledDocumentContainer = styled(Box)`
  width: 100%;

  @media print {
    height: auto;
  }
`;

export const VizDocumentContainer = (props: { children: React.ReactNode }) => {
  return <StyledDocumentContainer gap="large">{props.children}</StyledDocumentContainer>;
};
