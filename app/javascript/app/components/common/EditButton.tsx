import React from "react";
import _ from "lodash";
import { Button, ButtonProps } from "grommet";
import { Edit } from "./FlurishIcons";
import { IconProps } from "grommet-icons";

export const EditButton = (props: ButtonProps & { size?: IconProps["size"] }) => (
  <Button {..._.omit(props, ["size"])} hoverIndicator plain={false} icon={<Edit size={props.size} />} />
);
