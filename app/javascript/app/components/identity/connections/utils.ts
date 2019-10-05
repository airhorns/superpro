import { RouteComponentProps } from "react-router";
import queryString from "query-string";

export const returnToOrigin = (props: RouteComponentProps<any>) => {
  const origin = (queryString.parse(props.location.search).origin as string) || "/settings/connections";
  props.history.push(origin);
};
