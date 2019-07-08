import React from "react";
import { omit } from "lodash";
import { Button, ButtonProps } from "grommet";
import { Edit } from "./SuperproIcons";
import { IconProps } from "grommet-icons";

export const EditButton = (props: ButtonProps & { size?: IconProps["size"] }) => (
  <Button {...omit(props, ["size"])} hoverIndicator plain={false} icon={<Edit size={props.size} />} />
);
