import _ from "lodash";
import React from "react";
import { ErrorMessage, connect, getIn } from "formik";
import { Box, BoxProps, FormField } from "grommet";

export interface ControlWrapperProps {
  name: string;
  showErrorMessages?: boolean;
  label?: string;
  width?: BoxProps["width"];
  htmlFor?: string;
  children: React.ReactNode;
}

export const ControlWrapper = connect<ControlWrapperProps>(props => {
  const showErrorMessages = _.isUndefined(props.showErrorMessages) ? true : props.showErrorMessages;
  const error = getIn(props.formik.errors, props.name);

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
        {showErrorMessages && <ErrorMessage name={props.name} />}
      </>
    );
  }
});
