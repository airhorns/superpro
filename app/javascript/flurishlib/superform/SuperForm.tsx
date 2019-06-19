import { get, set, toPath } from "lodash";
import React from "react";
import Automerge from "automerge";
import { FieldPath, DocType } from "./utils";
import { ArrayHelpers } from "./ArrayHelpers";
import { SuperFormContext } from ".";

export type Command<T extends DocType> = (doc: T) => void;

export interface SuperFormProps<T extends DocType> {
  children: (form: SuperForm<T>) => React.ReactNode;
  initialValues?: T;
  onChange?: (doc: T, form: SuperForm<T>) => void;
  onSubmit?: (doc: T, form: SuperForm<T>) => void;
}

export type SuperFormErrors<T extends DocType> = {
  [K in keyof T]?: T[K] extends object ? SuperFormErrors<T[K]> : string;
};

interface SuperFormState<T extends DocType> {
  doc: T;
  errors: SuperFormErrors<T>;
}

export class SuperForm<T extends DocType> extends React.Component<SuperFormProps<T>, SuperFormState<T>> {
  currentBatch: Command<T>[] | null = null;

  constructor(props: SuperFormProps<T>) {
    super(props);
    let doc = Automerge.init<T>();

    if (this.props.initialValues) {
      doc = Automerge.change(doc, doc => Object.assign(doc, this.props.initialValues));
    }

    this.state = { doc, errors: {} };
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

  deletePath(path: FieldPath) {
    const keys = toPath(path);
    this.dispatch(doc => {
      const root = get(doc, keys.slice(0, keys.length - 1));
      delete root[keys[keys.length - 1]];
    });
  }

  dispatch = (command: Command<T>) => {
    // Queue up changes for the batch if batching is underway
    if (this.currentBatch) {
      this.currentBatch.push(command);
      return;
    }

    // Otherwise, setState the result of applying the passed command to the document using Automerge
    const prevDoc = this.state.doc;
    this.setState(
      prevState => {
        const newDoc = Automerge.change(prevState.doc, command);
        return { doc: newDoc };
      },
      () => {
        console.debug("doc", this.state.doc);
        console.debug("changes", Automerge.getChanges(prevDoc, this.state.doc));
        this.props.onChange && this.props.onChange(this.state.doc, this);
      }
    );
  };

  batch = (callback: () => void) => {
    this.currentBatch = [];
    callback();
    const commands = this.currentBatch;
    this.currentBatch = null;
    this.dispatch(doc => {
      commands.forEach(command => command(doc));
    });
  };

  markTouched(_path: FieldPath) {}

  getError(path: FieldPath) {
    return get(this.state.errors, path);
  }

  setError(path: FieldPath, message: string) {
    this.setState(prevState => ({
      ...prevState,
      errors: set(prevState.errors, path, message)
    }));
  }

  setErrors(errors: SuperFormErrors<T>) {
    this.setState({ errors });
  }

  arrayHelpers(path: FieldPath) {
    return new ArrayHelpers(path, this.dispatch);
  }

  render() {
    return (
      <SuperFormContext.Provider value={this}>
        <form
          onSubmit={e => {
            e.preventDefault();
            this.props.onSubmit && this.props.onSubmit(this.doc, this);
          }}
        >
          {this.props.children(this)}
        </form>
      </SuperFormContext.Provider>
    );
  }
}
