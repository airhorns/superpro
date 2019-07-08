import React from "react";
import getDisplayName from "react-display-name";

type FirstArgumentType<T> = T extends (arg: infer A, ...args: any[]) => any ? A : never;
export type AdopteeProps<T> = T extends React.ComponentType<infer Props>
  ? Props
  : T extends React.ReactElement<infer Props>
  ? Props
  : never;

type RenderPropType<T extends Adoptee, Props = AdopteeProps<T>> = Props extends ChildrenRenderProps
  ? FirstArgumentType<Props["children"]>
  : never;

export interface ChildrenRenderProps {
  children: (...args: any) => any;
}

export interface AdopteeComponentSpec<T> {
  component: React.ComponentType<ChildrenRenderProps & T>;
  props: T;
}

export type Adoptee = AdopteeComponentSpec<any> | React.ComponentType<ChildrenRenderProps>;

export interface AdoptMap {
  [key: string]: Adoptee;
}

export type AdoptionResult<Map extends AdoptMap> = { [K in keyof Map]: RenderPropType<Map[K]> };

export type ComposedAdoptedComponent<Map extends AdoptMap> = React.FC<{
  children?: (result: AdoptionResult<Map>) => React.ReactNode;
}>;

export const isComponentSpec = (adoptee: Adoptee): adoptee is AdopteeComponentSpec<any> =>
  adoptee.hasOwnProperty("component") && adoptee.hasOwnProperty("props");

export const adopt = <Map extends AdoptMap>(map: Map): ComposedAdoptedComponent<Map> => {
  const Final = (props: { children: (result: AdoptionResult<Map>) => React.ReactNode; result: AdoptionResult<Map> }) => {
    return props.children(props.result);
  };

  const Result = Object.entries(map).reduce(
    (next: React.ComponentType<any>, [key, entry]) => {
      let component: React.ComponentType<ChildrenRenderProps>;
      let props: any;

      if (isComponentSpec(entry)) {
        component = entry.component;
        props = entry.props;
      } else {
        component = entry;
        props = {};
      }

      return (carriedProps: { result: Partial<AdoptionResult<Map>>; children: (result: AdoptionResult<Map>) => React.ReactNode }) =>
        React.createElement(component, props, (resultForKey: any) => {
          const result = { ...carriedProps.result, [key]: resultForKey };
          return React.createElement(next, { result }, carriedProps.children);
        });
    },
    Final as any
  );

  (Result as any).displayName = `Adoption(${Object.values(map)
    .map(entry => (isComponentSpec(entry) ? getDisplayName(entry.component) : getDisplayName(entry)))
    .join(",")})`;

  return Result as ComposedAdoptedComponent<Map>;
};
