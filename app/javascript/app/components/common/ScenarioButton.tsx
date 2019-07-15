import React from "react";
import { Text, TextProps } from "grommet";

export const ScenarioButton = (props: { enabled: boolean } & TextProps) => (
  <Text style={{ filter: props.enabled ? "" : "grayscale(100%)" }} {...props}>
    🌤
  </Text>
);
