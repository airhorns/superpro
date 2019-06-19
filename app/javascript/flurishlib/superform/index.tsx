import React from "react";
import { DocType } from "./utils";
import { SuperForm } from "./SuperForm";

export * from "./utils";
export * from "./SuperForm";
export * from "./Input";
export * from "./NumberInput";
export * from "./Select";
export * from "./ArrayHelpers";
export * from "./SuperDatePicker";
export * from "./FieldBox";

export const SuperFormContext = React.createContext({});

export const useSuperForm = <T extends DocType>() => {
  const form = React.useContext(SuperFormContext);

  if (!form) {
    throw new Error("Can't use superform components outside a <SuperForm/> wrapper");
  }

  return form as SuperForm<T>;
};
