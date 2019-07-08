import { get, set, toPath } from "lodash";
import React from "react";
import { FieldPath, DocType } from "./utils";
import { ArrayHelpers } from "./ArrayHelpers";
import { SuperFormContext } from "../superform";
import { Backend, AutomergeBackend, Command } from "./Backends";
import { Box } from "grommet";

export interface SuperFormProps<T extends DocType> {
  children: (form: SuperForm<T>) => React.ReactNode;
  initialValues?: T;
  onChange?: (doc: T, form: SuperForm<T>) => void;
  onSubmit?: (doc: T, form: SuperForm<T>) => void;
  backendClass?: typeof Backend;
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
  backend: Backend<T>;

  constructor(props: SuperFormProps<T>) {
    super(props);

    // Initialize the backend
    const backendClass: any = props.backendClass || AutomergeBackend;
    this.backend = new backendClass((doc: T) => {
      const prevDoc = this.state.doc;
      this.setState({ doc }, () => {
        console.debug("doc", this.state.doc);
        console.debug("changes", this.backend.getChanges(prevDoc, this.state.doc));
        this.props.onChange && this.props.onChange(this.state.doc, this);
      });
    });

    if (this.props.initialValues) {
      this.backend.setInitialValues(this.props.initialValues);
    }

    this.state = { doc: this.backend.doc, errors: {} };
  }

  get doc(): T {
    return this.state.doc;
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

    // Otherwise, apply the change using the backend. The backend will call setState via it's onChange handler.
    this.backend.change(command);
  };

  batch = (callback: () => void) => {
    if (this.currentBatch) {
      // This is probably possible but it likely indicates the calling code isn't factored right, nested batches adds overhead and
      // commands should operate either at the batch level or atomic level, and batch level ones should only call atomic ones.
      throw new Error("can't nest superform batches");
    }

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

  canUndo() {
    return this.backend.canUndo();
  }

  canRedo() {
    return this.backend.canRedo();
  }

  undo() {
    return this.backend.undo();
  }

  redo() {
    return this.backend.redo();
  }

  render() {
    return (
      <SuperFormContext.Provider value={this}>
        <Box
          as="form"
          flex
          className="SuperForm"
          onSubmit={e => {
            e.preventDefault();
            this.props.onSubmit && this.props.onSubmit(this.doc, this);
          }}
        >
          {this.props.children(this)}
        </Box>
      </SuperFormContext.Provider>
    );
  }
}
