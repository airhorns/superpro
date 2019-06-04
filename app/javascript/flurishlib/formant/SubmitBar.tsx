import * as React from "react";
import { Box, Button, BoxProps } from "grommet";
import { FormikProps, connect } from "formik";

export interface StickySubmitBarProps {
  title?: string;
  width?: BoxProps["width"];
}

export const SubmitBar = connect<StickySubmitBarProps>(
  class extends React.Component<StickySubmitBarProps & { formik: FormikProps<any> }> {
    handleSubmit = () => {
      this.props.formik.handleSubmit();
    };

    render() {
      return (
        <Box width={this.props.width || "medium"} pad="medium">
          <Button
            data-test-id="submit"
            primary
            onClick={this.handleSubmit}
            disabled={this.props.formik.isSubmitting}
            label={this.props.title || "Save"}
          />
        </Box>
      );
    }
  }
);
