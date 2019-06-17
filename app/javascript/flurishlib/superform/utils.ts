import { toPath, omit } from "lodash";

export type DocType = object;
export type FieldPath = string[] | string;
export interface FieldProps {
  path: FieldPath;
}

export type Dispatcher<T extends DocType> = (callback: (doc: T) => void) => void;
export const pathToName = (path: FieldPath) => toPath(path).join(".");
export const propsForGrommetComponent = (props: any) => omit(props, ["validate", "name", "showErrorMessages", "storeAsSubunits"]);
