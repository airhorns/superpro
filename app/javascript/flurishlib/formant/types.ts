import { Omit } from "type-zoo";
import { FieldConfig as FormikFieldConfig } from "formik";

export type AcceptedFormikFieldProps = Omit<FormikFieldConfig, "component" | "render">;
