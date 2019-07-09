import Automerge from "automerge/src/automerge";
import { DocType } from "./utils";

export type OnChange<T extends DocType> = (newDoc: T) => void;
export type Command<T extends DocType> = (doc: T) => void;

export abstract class Backend<T extends DocType> {
  onChange: OnChange<T>;
  doc: T;

  constructor(onChange: OnChange<T>) {
    this.onChange = onChange;
    this.doc = {} as any;
  }

  abstract setInitialValues(initialValues: T): void;
  abstract change(command: Command<T>): void;
  abstract getChanges(oldDoc: T, newDoc: T): any[];
  abstract canUndo(): boolean;
  abstract canRedo(): boolean;
  abstract undo(): void;
  abstract redo(): void;
}

export class AutomergeBackend<T extends DocType> extends Backend<T> {
  constructor(onChange: OnChange<T>) {
    super(onChange);
    this.doc = Automerge.init<T>();
  }

  setInitialValues(initialValues: T) {
    this.doc = Automerge.change(this.doc, doc => Object.assign(doc, initialValues));
    // reset undo/redo state
    this.doc = Automerge.load(Automerge.save(this.doc));
  }

  change(command: Command<T>) {
    this.doc = Automerge.change(this.doc, command);
    this.onChange(this.doc);
  }

  getChanges(oldDoc: T, newDoc: T) {
    return Automerge.getChanges(oldDoc, newDoc);
  }

  canUndo() {
    return Automerge.canUndo(this.doc);
  }

  canRedo() {
    return Automerge.canRedo(this.doc);
  }

  undo() {
    this.doc = Automerge.undo(this.doc);
    this.onChange(this.doc);
  }

  redo() {
    this.doc = Automerge.redo(this.doc);
    this.onChange(this.doc);
  }
}

export class ObjectBackend<T extends DocType> extends Backend<T> {
  setInitialValues(initialValues: T) {
    this.doc = initialValues;
  }

  change(command: Command<T>) {
    command(this.doc);
    this.onChange(this.doc);
  }

  getChanges(_oldDoc: T, _newDoc: T) {
    return [];
  }

  canUndo() {
    return false;
  }

  canRedo() {
    return false;
  }

  undo() {}

  redo() {}
}
