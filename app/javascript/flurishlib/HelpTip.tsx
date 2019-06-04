import React from "react";
import { DropButton, DropButtonProps, Box, ButtonProps } from "grommet";
import { CircleQuestion } from "grommet-icons";

export const HelpTip = (
  props: { text: string; children?: React.ReactNode } & Partial<
    DropButtonProps & ButtonProps & { style: JSX.IntrinsicElements["button"]["style"] }
  >
) => {
  return (
    <DropButton
      {...props}
      dropContent={
        <Box pad="small" background={{ color: "light-2" }}>
          {props.text}
        </Box>
      }
    >
      {props.children || (
        <Box round="xsmall">
          <CircleQuestion />
        </Box>
      )}
    </DropButton>
  );
};
