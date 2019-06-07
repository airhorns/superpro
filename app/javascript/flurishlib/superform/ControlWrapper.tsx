import React from "react";
import _ from "lodash";
import { Box, BoxProps, FormField, Text } from "grommet";
import { useSuperForm } from ".";
import { DocType } from "./utils";

export interface ControlWrapperProps {
  name: string;
  label?: string;
  width?: BoxProps["width"];
  htmlFor?: string;
  children: React.ReactNode;
}

export const ControlWrapper = <T extends DocType>(props: ControlWrapperProps) => {
  const showErrorMessages = false;
  const form = useSuperForm<T>();
  const error = _.get(form.errors, props.name);

  if (props.label) {
    return (
      <Box width={props.width || "medium"}>
        <FormField label={props.label} htmlFor={props.htmlFor || props.name} error={showErrorMessages && error}>
          {props.children}
        </FormField>
      </Box>
    );
  } else {
    return (
      <>
        {props.children}
        {showErrorMessages && <Text color="status-critical">{error}</Text>}
      </>
    );
  }
};
