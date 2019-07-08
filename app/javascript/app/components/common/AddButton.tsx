import React from "react";
import { omit } from "lodash";
import { Button, ButtonProps, DropButton, DropButtonProps } from "grommet";
import { Add, IconProps } from "grommet-icons";

export const AddButtonProps = (size?: IconProps["size"]) => ({
  plain: false,
  icon: <Add size={size} />
});

export const AddButton = (props: ButtonProps & { size?: IconProps["size"] }) => (
  <Button {...AddButtonProps(props.size)} {...omit(props, ["size"])} />
);

export const AddDropButton = (props: DropButtonProps & ButtonProps & { size?: IconProps["size"] }) => (
  <DropButton {...AddButtonProps(props.size)} {...omit(props, ["size"])} />
);
