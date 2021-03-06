import { isUndefined, isFunction } from "lodash";
import React from "react";
import { Box, Button, ButtonProps, Layer } from "grommet";
import { FormClose } from "../app/components/common/SuperproIcons";

// Simple modal implementation that requires a trigger to open it.
// Pass an icon and/or label to get a button trigger automatically,
// or pass a trigger function that calls the callback to show the modal.
export interface SimpleModalProps {
  children?: React.ReactNode | React.ReactNode[] | ((setShow: (state: boolean) => void) => React.ReactNode);
  triggerLabel?: ButtonProps["label"];
  triggerIcon?: ButtonProps["icon"];
  trigger?: (setShow: (state: boolean) => void) => React.ReactNode;
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
  const content = isFunction(props.children) ? props.children(setShow) : props.children;
  const autoTrigger = (isUndefined(props.trigger) && !isUndefined(props.triggerLabel)) || !isUndefined(props.triggerIcon);

  return (
    <Box>
      {autoTrigger && <Button label={props.triggerLabel} icon={props.triggerIcon} onClick={onShow} hoverIndicator />}
      {props.trigger && props.trigger(setShow)}
      {show && <SimpleModalOverlay setShow={setShow}>{content}</SimpleModalOverlay>}
    </Box>
  );
};
