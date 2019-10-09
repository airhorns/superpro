import { get, set, isUndefined, isNull, isFunction, isArray, toPath, cloneDeep } from "lodash";
import memoizeOne from "memoize-one";
import queryString from "query-string";
import { DateTime } from "luxon";
import { ExecutionResult } from "@apollo/react-common";
import { SuperFormController, DocType, SuperFormErrors } from "./superform";
import { RouteComponentProps } from "react-router";
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

export interface SuperproStyleGraphQLError {
  field: string;
  relativeField: string;
  mutationClientId?: string;
  message: string;
}

export interface SuperproStyleRESTError {
  field: string;
  relative_field: string;
  mutation_client_id?: string;
  message: string;
}

export type SuccessfulMutationResponse<T> = {
  [K in keyof Omit<T, "errors">]: Exclude<T[K], null>;
};

export type ExecutionResultShape<Result extends ExecutionResult> = Result extends ExecutionResult<infer Shape> ? Shape : never;

// TypeScript incantation to get back the data asserting that it is present for a given mutation, detecting transport
// and validation errors at type check time
export const mutationSuccess = <
  Result extends ExecutionResult<Shape>,
  Shape = ExecutionResultShape<Result>,
  Key extends keyof Shape = keyof Shape
>(
  result: Result | undefined,
  key: Key
): SuccessfulMutationResponse<Exclude<Shape[Key], null>> | undefined => {
  if (result && !result.errors && result.data && !(result.data[key] as any).errors) {
    assert(result.data[key]);
    return result.data[key] as any;
  }

  return;
};

export const applyResponseErrors = <T extends DocType>(
  errors: (SuperproStyleGraphQLError | SuperproStyleRESTError)[],
  form: SuperFormController<T>
) => {
  const errorsObject: SuperFormErrors<T> = {};
  errors.forEach(error => {
    if ((error as SuperproStyleGraphQLError).mutationClientId) {
      set(
        errorsObject,
        `${(error as SuperproStyleGraphQLError).mutationClientId}.${(error as SuperproStyleGraphQLError).relativeField}`,
        error.message
      );
    } else if ((error as SuperproStyleRESTError).mutation_client_id) {
      set(
        errorsObject,
        `${(error as SuperproStyleRESTError).mutation_client_id}.${(error as SuperproStyleRESTError).relative_field}`,
        error.message
      );
    } else {
      console.warn("Received error from server response without a mutationClientId for client side association", error);
    }
  });
  form.setErrors(errorsObject);
};

export const RelayConnectionQueryUpdater = memoizeOne((connectionName: string) => (previousResult: any, { fetchMoreResult }: any) => {
  const path = toPath(connectionName);
  const fetchMoreConnection = get(fetchMoreResult, path);
  const previousConnection = get(previousResult, path);
  const newEdges = fetchMoreConnection.edges;
  const pageInfo = fetchMoreConnection.pageInfo;

  return newEdges.length
    ? set(
        cloneDeep(previousResult),
        connectionName,
        // Put the new nodes at the end of the list and update `pageInfo`
        // so we have the new `endCursor` and `hasNextPage` values
        {
          __typename: previousConnection.__typename,
          edges: [...previousConnection.edges, ...newEdges],
          pageInfo
        }
      )
    : previousResult;
});

export const replaceLocationWithNewParams = (
  params: { [key: string]: any },
  location: RouteComponentProps["location"],
  history: RouteComponentProps["history"]
) => {
  const string = queryString.stringify(params);
  const newLocation = string.length > 0 ? `${location.pathname}?${string}` : location.pathname;
  history.replace(newLocation);
};
