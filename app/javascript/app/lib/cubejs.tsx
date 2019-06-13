import React from "react";
import { isEqual, toPairs, fromPairs } from "lodash";
import cubejs from "@cubejs-client/core";

export const CubeJSAPI = cubejs("whatever", {
  apiUrl: "https://cube.ggt.dev/cubejs-api/v1/"
});

export interface QueryDescriptor {
  measures?: string[];
  dimensions?: any[];
  timeDimensions?: any[];
  filters?: any;
  renewQuery?: boolean;
}

export interface CubeQueryProps {
  query?: QueryDescriptor;
  queries?: QueryDescriptor[];
  children: (queryResult: { loading: boolean; error: any; resultSet: any; refresh: () => void }) => React.ReactNode;
}

interface CubeQueryState {
  loading: boolean;
  resultSet: null | any;
  error: null | any;
}

export class CubeQuery extends React.Component<CubeQueryProps, CubeQueryState> {
  state: CubeQueryState = { loading: false, resultSet: null, error: null };
  mutexObj: any = {};

  componentDidMount() {
    const { query, queries } = this.props;
    if (query) {
      this.load(query);
    }
    if (queries) {
      this.loadQueries(queries);
    }
  }

  componentDidUpdate(prevProps: CubeQueryProps) {
    const { query, queries } = this.props;
    if (query && !isEqual(prevProps.query, query)) {
      this.refresh();
    } else if (queries && !isEqual(prevProps.queries, queries)) {
      this.refresh();
    }
  }

  isQueryPresent(query: QueryDescriptor) {
    return (
      (query.measures && query.measures.length) ||
      (query.dimensions && query.dimensions.length) ||
      (query.timeDimensions && query.timeDimensions.length)
    );
  }

  load(query: QueryDescriptor) {
    this.setState({ loading: true, error: null });

    if (query && this.isQueryPresent(query)) {
      CubeJSAPI.load(query, { mutexObj: this.mutexObj, mutexKey: "query" })
        .then((resultSet: any) => this.setState({ resultSet, error: null, loading: false }))
        .catch((error: any) => this.setState({ resultSet: null, error, loading: false }));
    }
  }

  loadQueries(queries: QueryDescriptor[]) {
    this.setState({ loading: true, error: null });

    const resultPromises = Promise.all(
      toPairs(queries).map(([name, query]) =>
        CubeJSAPI.load(query, { mutexObj: this.mutexObj, mutexKey: name }).then((r: any) => [name, r])
      )
    );

    resultPromises
      .then(resultSet =>
        this.setState({
          resultSet: fromPairs(resultSet),
          error: null,
          loading: false
        })
      )
      .catch(error => this.setState({ resultSet: null, error, loading: false }));
  }

  refresh = () => {
    if (this.props.query) {
      this.load(this.props.query);
    } else if (this.props.queries) {
      this.loadQueries(this.props.queries);
    }
  };

  render() {
    const loadState = {
      error: this.state.error,
      resultSet: this.state.resultSet,
      loading: this.state.loading,
      refresh: this.refresh
    };

    return this.props.children(loadState);
  }
}
