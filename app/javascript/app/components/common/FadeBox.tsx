import styled from "styled-components";

export const FadeBox = styled.div<{ visible: boolean }>`
  ${props =>
    `
    opacity: ${props.visible ? "1" : "0"};
    transition: opacity 100ms ease-in-out;
  `};
`;
