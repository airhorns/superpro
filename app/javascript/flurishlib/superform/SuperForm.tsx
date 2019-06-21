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
      // reset undo/redo state
      doc = Automerge.load(Automerge.save(doc));
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
    return Automerge.canUndo(this.state.doc);
  }

  canRedo() {
    return Automerge.canRedo(this.state.doc);
  }

  undo() {
    this.setState(
      prevState => ({ doc: Automerge.undo(prevState.doc) }),
      () => {
        this.props.onChange && this.props.onChange(this.state.doc, this);
      }
    );
  }

  redo() {
    this.setState(
      prevState => ({ doc: Automerge.redo(prevState.doc) }),
      () => {
        this.props.onChange && this.props.onChange(this.state.doc, this);
      }
    );
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
