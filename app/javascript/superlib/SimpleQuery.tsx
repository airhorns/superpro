import * as React from "react";
import * as ApolloReactComponents from "@apollo/react-components";
import { AssertedKeys, assertKeys } from "./utils";
import { Alert } from "./Alert";
import { PageLoadSpin } from "./Spin";
import { Omit } from "type-zoo";
import { QueryResult } from "@apollo/react-common";
import { isEqual } from "lodash";

// gql-gen generates SFCs that omit the variables key from the QueryProps then & with a { variables: Variables } that is mandatory or a {variables?: Variables } that isnt in order to better type check the invocations of the component. This makes it real annoying to dereference.
export type GeneratedQueryComponentType<Data, Variables> =
  | React.ComponentType<
      Omit<ApolloReactComponents.QueryComponentOptions<Data, Variables>, "query" | "variables"> & { variables?: Variables }
    >
  | React.ComponentType<
      Omit<ApolloReactComponents.QueryComponentOptions<Data, Variables>, "query" | "variables"> & { variables: Variables }
    >;

export type ComponentDataType<Component> = Component extends GeneratedQueryComponentType<infer Data, any> ? Data : never;
export type ComponentVariablesType<Component> = Component extends GeneratedQueryComponentType<any, infer Variables> ? Variables : never;

export type AutoAssert<Data> = AssertedKeys<Data, keyof Data>;

// type ComponentVariablesType<Component extends GeneratedQueryComponentType<any, any>> = React.ComponentPropsWithRef<Component>["variables"];

export interface SimpleQueryProps<
  Data,
  Variables,
  RequiredKeys extends keyof Data,
  Component extends GeneratedQueryComponentType<Data, Variables>
> extends Omit<ApolloReactComponents.QueryComponentOptions<Data, Variables>, "children" | "query" | "variables"> {
  component: Component;
  variables?: Variables;
  children?: (data: AssertedKeys<Data, RequiredKeys>, result: QueryResult<Data, Variables>) => React.ReactNode;
  require?: RequiredKeys[]; // properties to ensure are present in the returned data. If they aren't, render a 404
  spinForSubsequentLoads?: boolean;
}

// Handy component to handle errors and loading states for big and simple loads all in one place, and return data with a stricter
// type to the children callback.
// The react-apollo QueryRenderer callback used to look like this:
//    ({result: TData?, error: TError?, loading: boolean}) => React.ReactNode
// And with this component it will look like this:
//    (result: TData) => React.ReactNode
// Props:
//  component: React.Component subclass, usually from the graph.tsx file. Required. Keeps everything type safe.
//  require?: List of keys to make sure are present in the returned data from the server. 404s the page otherwise and removes need for extra type checks.
// Does some gross types bullshit to automagically gaurantee that the keys on the query are in fact available to the
// callback function so they don't have to do a bunch of nullchecks.
export class SimpleQuery<
  Component extends GeneratedQueryComponentType<Data, Variables>,
  RequiredKeys extends keyof Data,
  Data = ComponentDataType<Component>,
  Variables = ComponentVariablesType<Component>
> extends React.Component<SimpleQueryProps<Data, Variables, RequiredKeys, Component>> {
  handleResult = (result: QueryResult<Data, Variables>) => {
    if (result.loading) {
      if (!result.data || isEqual(result.data, {}) || (result.data && this.props.spinForSubsequentLoads)) {
        return <PageLoadSpin />;
      }
    }

    if (result.error || !result.data) {
      console.error("Error loading data from backend", result.error);
      return <Alert message="There was an internal error. Please refresh the page and try again." type="error" />;
    }

    // Handle 404s from the server for nullable queries
    const data = assertKeys(result.data, this.props.require || []);
    if (!data) {
      return <Alert message="Data Not Found" type="error" />;
    }

    return this.props.children && this.props.children(data, result);
  };

  render() {
    return <this.props.component {...(this.props as any)}>{this.handleResult}</this.props.component>;
  }
}
