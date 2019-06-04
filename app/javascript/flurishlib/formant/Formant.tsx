import * as _ from "lodash";
import * as React from "react";
import { Formik, FormikConfig, FormikProps, Form } from "formik";
import { Input } from "./Input";
import { Select } from "./Select";
import { ControlWrapper } from "./ControlWrapper";
import { Switch } from "./Switch";

type AcceptedFormikProps<Values> = Pick<FormikConfig<Values>, Exclude<keyof FormikConfig<Values>, "component" | "render" | "children">>;

export interface FormantProps<Values> extends AcceptedFormikProps<Values> {
  children: ((props: FormikProps<Values>) => React.ReactNode) | React.ReactNode;
}

export class Formant<Values> extends React.Component<FormantProps<Values>> {
  static Input = Input;
  static Select = Select;
  static ControlWrapper = ControlWrapper;
  static Switch = Switch;

  render() {
    return (
      <Formik {..._.omit(this.props, "children")}>
        {props => {
          return <Form>{_.isFunction(this.props.children) ? this.props.children(props) : this.props.children}</Form>;
        }}
      </Formik>
    );
  }
}
