import { isUndefined } from "lodash";
import React from "react";
import { Box, BoxProps, Text, FormField } from "grommet";
import { DocType, useSuperForm } from "../superform";

export interface FieldBoxProps {
  path: string;
  showErrorMessages?: boolean;
  label?: string;
  width?: BoxProps["width"];
  htmlFor?: string;
  children: React.ReactNode;
}

export const FieldBox = <T extends DocType>(props: FieldBoxProps) => {
  const form = useSuperForm<T>();
  const showErrorMessages = isUndefined(props.showErrorMessages) ? true : props.showErrorMessages;
  const error = form.getError(props.path); // someday this should be actually implemented on the form object

  if (props.label) {
    return (
      <Box width={props.width || "medium"}>
        <FormField label={props.label} htmlFor={props.htmlFor || props.path} error={showErrorMessages && error}>
          {props.children}
        </FormField>
      </Box>
    );
  } else {
    return (
      <>
        {props.children}
        {showErrorMessages && error && <Text color="status-critical">{error}</Text>}
      </>
    );
  }
};
