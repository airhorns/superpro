import React from "react";
import { DocType } from "./utils";
import { Backend } from "./Backends";
import { Box, BoxProps } from "grommet";
import { SuperFormController, SuperFormErrors } from "./SuperFormController";

export const SuperFormContext = React.createContext<SuperFormController<any>>({} as any);

export const useSuperForm = <T extends DocType>() => {
  const controller = React.useContext(SuperFormContext);

  if (!controller) {
    throw new Error("Can't use superform components outside a <SuperForm/> wrapper");
  }

  return controller as SuperFormController<T>;
};

export interface SuperFormProps<T extends DocType> {
  children: (form: SuperFormController<T>) => React.ReactNode;
  initialValues: T;
  onChange?: (doc: T, form: SuperFormController<T>) => void;
  onSubmit?: (doc: T, form: SuperFormController<T>) => void;
  backendClass?: typeof Backend;
  containerProps?: Partial<BoxProps>;
}

interface SuperFormState<T extends DocType> {
  doc: T;
  errors: SuperFormErrors<T>;
}

export class SuperForm<T extends DocType> extends React.Component<SuperFormProps<T>, SuperFormState<T>> {
  controller: SuperFormController<T>;

  constructor(props: SuperFormProps<T>) {
    super(props);

    // Initialize the controller
    this.controller = new SuperFormController<T>(
      props.initialValues,
      (newDoc, _oldDoc, controller) => {
        this.setState({ doc: controller.doc, errors: controller.errors }, () => {
          this.props.onChange && this.props.onChange(this.controller.doc, this.controller);
        });
      },
      props.backendClass
    );

    this.state = { doc: this.controller.doc, errors: this.controller.errors };
  }

  handleSubmit = (e: React.SyntheticEvent) => {
    e.preventDefault();
    this.props.onSubmit && this.props.onSubmit(this.controller.doc, this.controller);
  };

  render() {
    return (
      <SuperFormContext.Provider value={this.controller}>
        <Box as="form" flex="grow" className="SuperForm" onSubmit={this.handleSubmit} {...this.props.containerProps}>
          {this.props.children(this.controller)}
        </Box>
      </SuperFormContext.Provider>
    );
  }
}
