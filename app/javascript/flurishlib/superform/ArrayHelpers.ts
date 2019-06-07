import { DocType, FieldPath, Dispatcher } from "./utils";
import { get } from "lodash";
import { List } from "automerge";
import { assert } from "flurishlib";

export type ArrayHelperListFunctions<E> = Pick<List<E>, "push" | "pop" | "shift" | "unshift" | "insertAt" | "deleteAt" | "splice">;

export class ArrayHelpers<T extends DocType, E extends any> implements ArrayHelperListFunctions<E> {
  path: FieldPath;
  dispatch: Dispatcher<T>;

  constructor(path: FieldPath, dispatch: Dispatcher<T>) {
    this.path = path;
    this.dispatch = dispatch;
  }

  push(...args: E[]) {
    return this.change(list => list.push(...args));
  }

  pop() {
    return this.change(list => list.pop());
  }

  shift() {
    return this.change(list => list.shift());
  }

  unshift(...args: E[]) {
    return this.change(list => list.unshift(...args));
  }

  insertAt(index: number, ...args: E[]) {
    return this.change(list => assert(list.insertAt)(index, ...args));
  }

  deleteAt(index: number) {
    return this.change(list => assert(list.deleteAt)(index));
  }

  splice(start: number, numToDelete: number, ...insertions: E[]) {
    return this.change(list => list.splice(start, numToDelete, ...insertions));
  }

  change<T>(callback: (list: List<E>) => T): T {
    let returnValue;

    this.dispatch(doc => {
      const list = get(doc, this.path);
      returnValue = callback(list);
    });

    return (returnValue as unknown) as T;
  }
}
