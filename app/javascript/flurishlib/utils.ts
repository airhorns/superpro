import { set, isUndefined, isNull, isFunction, isArray } from "lodash";
import memoizeOne from "memoize-one";
import HTML5Backend from "react-dnd-html5-backend";
import createTouchBackend from "react-dnd-touch-backend";
import { DragDropManager, Backend } from "dnd-core";
import { DateTime } from "luxon";
import { FetchResult } from "react-apollo";
import { SuperForm, DocType, SuperFormErrors } from "./superform";
export type AssertedKeys<T, K extends keyof T> = { [Key in K]: NonNullable<T[Key]> } & T;

export function assert<T>(value: T | undefined | null): T {
  if (!value) {
    throw new Error("assertion error");
  }
  return value;
}

export function assertKeys<T extends { [key: string]: any }, K extends keyof T>(object: T, keys: K[]) {
  for (let key of keys) {
    if (isUndefined(object[key]) || isNull(object[key])) {
      return false;
    }
  }
  return object as AssertedKeys<T, K>;
}

export const encodeURIParams = (params: { [key: string]: string }) =>
  Object.entries(params)
    .map(([key, val]) => `${encodeURIComponent(key)}=${encodeURIComponent(val)}`)
    .join("&");

export function invokeIfNeeded<T, U extends any[]>(f: T | ((...args: U) => T), args: U) {
  return isFunction(f) ? f(...args) : f;
}

export const isArrayOptionType = <T extends object>(value: T | readonly T[]): value is readonly T[] => isArray(value);
export const isValueOptionType = <T extends object>(value: T | readonly T[]): value is T => value.hasOwnProperty("value");

export type ISO8601DateString = string;
export const formatDate = (str: ISO8601DateString) => DateTime.fromISO(str).toLocaleString(DateTime.DATE_FULL);

export const isTouchDevice = memoizeOne(() => {
  var prefixes = " -webkit- -moz- -o- -ms- ".split(" ");
  var mq = (query: any) => {
    return window.matchMedia(query).matches;
  };

  if ("ontouchstart" in window || ((window as any).DocumentTouch && document instanceof (window as any).DocumentTouch)) {
    return true;
  }

  // include the 'heartz' as a way to have a non matching MQ to help terminate the join
  // https://git.io/vznFH
  var query = ["(", prefixes.join("touch-enabled),("), "heartz", ")"].join("");
  return mq(query);
});

const hasNativeElementsFromPoint = typeof document != "undefined" && (document.elementsFromPoint || document.msElementsFromPoint);

const getDropTargetElementsAtPoint = (x: number, y: number, dropTargets: HTMLElement[]) => {
  return dropTargets.filter(t => {
    const rect = t.getBoundingClientRect();
    return x >= rect.left && x <= rect.right && y <= rect.bottom && y >= rect.top;
  });
};

export const DnDBackendForDevice = () => {
  if (isTouchDevice()) {
    return createTouchBackend({
      getDropTargetElementsAtPoint: hasNativeElementsFromPoint ? getDropTargetElementsAtPoint : undefined
    }) as ((manager: DragDropManager<any>) => Backend);
  } else {
    return HTML5Backend;
  }
};

const hasOwnProperty = Object.prototype.hasOwnProperty;
export const shallowEqual = (objA: any, objB: any): boolean => {
  if (Object.is(objA, objB)) {
    return true;
  }

  if (typeof objA !== "object" || objA === null || typeof objB !== "object" || objB === null) {
    return false;
  }

  const keysA = Object.keys(objA);
  const keysB = Object.keys(objB);

  if (keysA.length !== keysB.length) {
    return false;
  }

  // Test for A's keys different from B.
  for (let i = 0; i < keysA.length; i++) {
    if (!hasOwnProperty.call(objB, keysA[i]) || !Object.is(objA[keysA[i]], objB[keysA[i]])) {
      return false;
    }
  }

  return true;
};

export const shallowSubsetEqual = (keys: string[], objA: any, objB: any): boolean => {
  if (Object.is(objA, objB)) {
    return true;
  }

  if (typeof objA !== "object" || objA === null || typeof objB !== "object" || objB === null) {
    return false;
  }

  for (let i = 0; i < keys.length; i++) {
    if (!hasOwnProperty.call(objB, keys[i]) || !Object.is(objA[keys[i]], objB[keys[i]])) {
      return false;
    }
  }

  return true;
};

export interface FlurishStyleGraphQLError {
  field: string;
  relativeField: string;
  mutationClientId?: string;
  message: string;
}

export interface FlurishStyleRESTError {
  field: string;
  relative_field: string;
  mutation_client_id?: string;
  message: string;
}

export interface FlurishStyleMutationResult {
  errors: {
    field: string;
  }[];
  [key: string]: any;
}

export const mutationSuccessful = <T extends FlurishStyleMutationResult>(result: void | FetchResult<T>): result is FetchResult<T> => {
  return !!(result && !result.errors);
};

export const applyResponseErrors = <T extends DocType>(
  errors: (FlurishStyleGraphQLError | FlurishStyleRESTError)[],
  form: SuperForm<T>
) => {
  const errorsObject: SuperFormErrors<T> = {};
  errors.forEach(error => {
    if ((error as FlurishStyleGraphQLError).mutationClientId) {
      set(
        errorsObject,
        `${(error as FlurishStyleGraphQLError).mutationClientId}.${(error as FlurishStyleGraphQLError).relativeField}`,
        error.message
      );
    } else if ((error as FlurishStyleRESTError).mutation_client_id) {
      set(
        errorsObject,
        `${(error as FlurishStyleRESTError).mutation_client_id}.${(error as FlurishStyleRESTError).relative_field}`,
        error.message
      );
    } else {
      console.warn("Received error from server response without a mutationClientId for client side association", error);
    }
  });
  form.setErrors(errorsObject);
};
