import Automerge from "automerge/src/automerge";
import { DocType } from "./utils";

export type OnChange<T extends DocType> = (newDoc: T, previousDoc: T) => void;
export type Command<T extends DocType> = (doc: T) => void;

export abstract class Backend<T extends DocType> {
  onChange: OnChange<T>;
  doc: T;

  constructor(onChange: OnChange<T>) {
    this.onChange = onChange;
    this.doc = {} as any;
  }

  abstract resetDoc(doc: T): void;
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

  resetDoc(doc: T) {
    this.doc = Automerge.change(Automerge.init<T>(), emptyDoc => Object.assign(emptyDoc, doc));
  }

  change(command: Command<T>) {
    this.setDoc(Automerge.change(this.doc, command));
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
    this.setDoc(Automerge.undo(this.doc));
  }

  redo() {
    this.setDoc(Automerge.redo(this.doc));
  }

  private setDoc(newDoc: T) {
    const prevDoc = this.doc;
    this.doc = newDoc;
    this.onChange(this.doc, prevDoc);
  }
}

export class ObjectBackend<T extends DocType> extends Backend<T> {
  resetDoc(initialValues: T) {
    this.doc = initialValues;
  }

  change(command: Command<T>) {
    const prevDoc = this.doc;
    command(this.doc);
    this.onChange(this.doc, prevDoc);
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
