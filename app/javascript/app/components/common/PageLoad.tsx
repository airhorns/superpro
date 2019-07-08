import { SimpleQuery } from "superlib";
import { GeneratedQueryComponentType, ComponentDataType, ComponentVariablesType } from "superlib/SimpleQuery";

export class PageLoad<
  Component extends GeneratedQueryComponentType<Data, Variables>,
  RequiredKeys extends keyof Data,
  Data = ComponentDataType<Component>,
  Variables = ComponentVariablesType<Component>
> extends SimpleQuery<Component, RequiredKeys, Data, Variables> {
  static defaultProps = {
    fetchPolicy: "cache-and-network"
  };
}
