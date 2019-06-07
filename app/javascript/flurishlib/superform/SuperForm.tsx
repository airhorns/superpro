import { isFunction, get, set } from "lodash";
import React from "react";
import Automerge from "automerge";
import { FieldPath, DocType } from "./utils";
import { ArrayHelpers } from "./ArrayHelpers";
import { SuperFormContext } from ".";

export interface SuperFormProps<T extends DocType> {
  children: React.ReactNode | ((form: SuperForm<T>) => React.ReactNode);
  initialValues?: T;
}

export class SuperForm<T extends DocType> extends React.Component<SuperFormProps<T>, { doc: T }> {
  errors: { [key: string]: string } = {};

  constructor(props: SuperFormProps<T>) {
    super(props);
    let doc = Automerge.init<T>();

    if (this.props.initialValues) {
      doc = Automerge.change(doc, doc => Object.assign(doc, this.props.initialValues));
    }

    this.state = { doc };
  }

  get doc(): T {
    return this.state.doc;
  }

  objectId(object: any) {
    return Automerge.getObjectId(object);
  }

  getValue(path: FieldPath) {
    return get(this.state.doc, path);
  }

  setValue(path: FieldPath, value: any) {
    this.dispatch(doc => set(doc, path, value));
  }

  dispatch(command: (doc: T) => void) {
    this.setState(prevState => {
      const newDoc = Automerge.change(prevState.doc, command);
      return { doc: newDoc };
    });
  }

  markTouched(_path: FieldPath) {}

  arrayHelpers(path: FieldPath) {
    return new ArrayHelpers(path, this.dispatch);
  }

  render() {
    return (
      <SuperFormContext.Provider value={this}>
        <form>{isFunction(this.props.children) ? this.props.children(this) : this.props.children}</form>
      </SuperFormContext.Provider>
    );
  }
}
