import { DocType, FieldPath, Dispatcher } from "./utils";
import { get } from "lodash";
import { List } from "automerge";

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
    return this.change(list => {
      if (list.insertAt) {
        return list.insertAt(index, ...args);
      } else {
        return list.splice(index, 0, ...args);
      }
    });
  }

  deleteAt(index: number) {
    return this.change(list => {
      if (list.deleteAt) {
        return list.deleteAt(index);
      } else {
        return list.splice(index, 1);
      }
    });
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
