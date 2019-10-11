import { get, set, toPath } from "lodash";
import { FieldPath, DocType } from "./utils";
import { ArrayHelpers } from "./ArrayHelpers";
import { Backend, AutomergeBackend, Command } from "./Backends";

export type SuperFormErrors<T extends DocType> = {
  [K in keyof T]?: T[K] extends object ? SuperFormErrors<T[K]> : string;
};

export type SuperFormChangeCallback<T extends DocType> = (newDoc: T, previousDoc: T, controller: SuperFormController<T>) => void;

export class SuperFormController<T extends DocType> {
  currentBatch: Command<T>[] | null = null;
  backend: Backend<T>;
  errors: SuperFormErrors<T> = {};
  clock = 0;

  constructor(initialDoc: T, onChange: SuperFormChangeCallback<T>, backendClass: typeof Backend = AutomergeBackend) {
    // Initialize the backend
    this.backend = new (backendClass as any)((doc: T, prevDoc: T) => {
      console.debug("doc", doc);
      console.debug("changes", this.backend.getChanges(prevDoc, doc));
      onChange(doc, prevDoc, this);
    });

    this.backend.resetDoc(initialDoc);
  }

  get doc(): T {
    return this.backend.doc as T;
  }

  getValue(path: FieldPath) {
    return get(this.backend.doc, path);
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

    // Otherwise, apply the change using the backend. The backend will call the onChange callback passed in the constructor.
    this.backend.change(command);
    this.clock += 1;
  };

  batch = (batchDefinition: () => void) => {
    if (this.currentBatch) {
      // This is probably possible but it likely indicates the calling code isn't factored right, nested batches adds overhead and
      // commands should operate either at the batch level or atomic level, and batch level ones should only call atomic ones.
      throw new Error("can't nest superform batches");
    }

    this.currentBatch = [];
    batchDefinition();
    const commands = this.currentBatch;
    this.currentBatch = null;
    this.dispatch(doc => {
      commands.forEach(command => command(doc));
    });
  };

  markTouched(_path: FieldPath) {
    return;
  }

  getError(path: FieldPath) {
    return get(this.errors, path);
  }

  setError(path: FieldPath, message: string) {
    set(this.errors, path, message);
  }

  setErrors(errors: SuperFormErrors<T>) {
    Object.assign(this.errors, errors);
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
}
