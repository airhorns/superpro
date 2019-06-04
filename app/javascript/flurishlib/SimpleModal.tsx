import _ from "lodash";
import React from "react";
import { Box, Button, ButtonProps, Layer } from "grommet";
import { FormClose } from "../app/components/common/FlurishIcons";

export interface SimpleModalProps {
  children?: React.ReactNode | React.ReactNode[] | ((setShow: (state: boolean) => void) => React.ReactNode);
  triggerLabel?: ButtonProps["label"];
  triggerIcon?: ButtonProps["icon"];
}

export const SimpleModal = (props: SimpleModalProps) => {
  const [show, setShow] = React.useState();
  const onShow = () => setShow(true);

  return (
    <Box>
      <Button label={props.triggerLabel} icon={props.triggerIcon} onClick={onShow} hoverIndicator />
      {show && (
        <Layer onEsc={() => setShow(false)} onClickOutside={() => setShow(false)} margin="large">
          <Box>
            <Box pad="medium" overflow={{ vertical: "auto" }}>
              {_.isFunction(props.children) ? props.children(setShow) : props.children}
            </Box>
            <Button
              primary
              icon={<FormClose />}
              onClick={() => setShow(false)}
              style={{ position: "absolute", top: "-1.5em", right: "-1.5em" }}
            />
          </Box>
        </Layer>
      )}
    </Box>
  );
};
