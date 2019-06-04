import React from "react";
import _ from "lodash";
import { Button, ButtonProps } from "grommet";
import { Trash, IconProps } from "grommet-icons";

export const TrashButton = (props: ButtonProps & { size?: IconProps["size"] }) => (
  <Button {..._.omit(props, ["size"])} hoverIndicator plain={false} color="status-critical" icon={<Trash size={props.size} />} />
);
