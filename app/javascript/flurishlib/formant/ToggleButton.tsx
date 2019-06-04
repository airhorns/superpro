import * as React from "react";
import { Button, ButtonProps } from "grommet";
import { FormikProps, getIn, connect } from "formik";

export interface ToggleButtonProps extends ButtonProps {
  name: string;
  trueContents: React.ReactNode;
  falseContents: React.ReactNode;
}

export const ToggleButton = connect<ToggleButtonProps>(
  class extends React.Component<ToggleButtonProps & { formik: FormikProps<any> }> {
    setValue(value: boolean) {
      this.props.formik.setFieldValue(this.props.name, value);
    }

    render() {
      const value = getIn(this.props.formik.values, this.props.name);
      return <Button onClick={() => this.setValue(!value)}>{value ? this.props.trueContents : this.props.falseContents}</Button>;
    }
  }
);
