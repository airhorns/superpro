import _ from "lodash";
import React from "react";
import { Box, Button, ButtonProps, Layer } from "grommet";
import { FormClose } from "../app/components/common/FlurishIcons";

export interface SimpleModalProps {
  children?: React.ReactNode | React.ReactNode[] | ((setShow: (state: boolean) => void) => React.ReactNode);
  triggerLabel?: ButtonProps["label"];
  triggerIcon?: ButtonProps["icon"];
}

export const SimpleModalOverlay = (props: { children: React.ReactNode; setShow: (state: boolean) => void }) => (
  <Layer onEsc={() => props.setShow(false)} onClickOutside={() => props.setShow(false)} margin="large">
    <Box>
      <Box pad="medium" overflow={{ vertical: "auto" }}>
        {props.children}
      </Box>
      <Button
        primary
        icon={<FormClose />}
        onClick={() => props.setShow(false)}
        style={{ position: "absolute", top: "-1.5em", right: "-1.5em" }}
      />
    </Box>
  </Layer>
);

export const SimpleModal = (props: SimpleModalProps) => {
  const [show, setShow] = React.useState();
  const onShow = () => setShow(true);
  const content = _.isFunction(props.children) ? props.children(setShow) : props.children;

  return (
    <Box>
      {props.triggerLabel ||
        (props.triggerIcon && <Button label={props.triggerLabel} icon={props.triggerIcon} onClick={onShow} hoverIndicator />)}
      {show && <SimpleModalOverlay setShow={setShow}>{content}</SimpleModalOverlay>}
    </Box>
  );
};
