import React from "react";
import { DocType } from "./utils";
export * from "./utils";
import { SuperForm } from "./SuperForm";
export { SuperForm } from "./SuperForm";
export { Input } from "./Input";
export { NumberInput } from "./NumberInput";
export { Select } from "./Select";
export { ArrayHelpers } from "./ArrayHelpers";
export { SuperDatePicker } from "./SuperDatePicker";

export const SuperFormContext = React.createContext({});

export const useSuperForm = <T extends DocType>() => {
  const form = React.useContext(SuperFormContext);

  if (!form) {
    throw new Error("Can't use superform components outside a <SuperForm/> wrapper");
  }

  return form as SuperForm<T>;
};
