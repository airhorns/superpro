import React from "react";
import queryString from "query-string";
import { __RouterContext, RouteComponentProps } from "react-router";
import { Filter } from "../../WarehouseQuery";

const StorageContext = React.createContext<GlobalFilterController>(null as any);

export type GlobalFilterID = "start_date" | "end_date" | "duration_key" | "business_line_id";

export interface GlobalFilterSet {
  filters: {
    [id in GlobalFilterID]?: { operator: Filter["operator"]; values: Filter["values"] };
  };
}

export class GlobalFilterController {
  history: RouteComponentProps["history"];
  location: RouteComponentProps["location"];
  state: GlobalFilterSet;
  baseQueryParams: { [key: string]: any };

  static Context = StorageContext;
  static Provider = (props: { children: React.ReactNode }) => {
    const { location, history } = React.useContext(__RouterContext);
    const controller = React.useMemo(() => new GlobalFilterController(history, location), [history, location]);
    return <StorageContext.Provider value={controller}>{props.children}</StorageContext.Provider>;
  };

  static Consumer = StorageContext.Consumer;

  constructor(history: RouteComponentProps["history"], location: RouteComponentProps["location"]) {
    this.history = history;
    this.location = location;
    this.state = { filters: {} };

    const { filters, ...rest } = queryString.parse(this.location.search);
    this.baseQueryParams = rest;
    if (filters) {
      this.state.filters = JSON.parse(filters as string) as GlobalFilterSet["filters"];
    }
  }

  removeFilter(id: GlobalFilterID) {
    this.dispatch(() => {
      delete this.state.filters[id];
    });
  }

  setFilter(id: GlobalFilterID, operator: Filter["operator"], values: Filter["values"]) {
    this.dispatch(() => {
      this.state.filters[id] = { operator, values };
    });
  }

  dispatch(fn: () => void) {
    fn();
    this.history.push({
      pathname: this.location.pathname,
      search: "?" + queryString.stringify({ ...this.baseQueryParams, filters: JSON.stringify(this.state.filters) })
    });
  }
}
