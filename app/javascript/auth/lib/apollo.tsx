import { ApolloClient } from "apollo-client";
import { InMemoryCache, IntrospectionFragmentMatcher } from "apollo-cache-inmemory";
import { HttpLink } from "apollo-link-http";
import { onError } from "apollo-link-error";
import { ApolloLink } from "apollo-link";
import introspectionResult from "../auth-graph-introspection";
import { csrfToken } from "../../flurishlib";

export const client = new ApolloClient({
  link: ApolloLink.from([
    new ApolloLink((operation, forward) => {
      operation.setContext({
        uri: `/graphql?operation=${operation.operationName}`
      });

      return (forward as any)(operation);
    }),
    onError(({ graphQLErrors, networkError }) => {
      if (graphQLErrors)
        graphQLErrors.map(({ message, locations, path }) =>
          console.log(`[GraphQL error]: Message: ${message}, Location: ${locations}, Path: ${path}`)
        );
      if (networkError) console.log(`[Network error]: ${networkError}`);
    }),
    new HttpLink({
      uri: "/graphql",
      credentials: "same-origin",
      headers: {
        "X-CSRF-Token": csrfToken()
      }
    })
  ]),
  cache: new InMemoryCache({
    addTypename: true,
    fragmentMatcher: new IntrospectionFragmentMatcher({
      introspectionQueryResultData: introspectionResult
    })
  }),
  defaultOptions: {
    watchQuery: {
      fetchPolicy: "network-only",
      errorPolicy: "ignore"
    },
    query: {
      fetchPolicy: "network-only",
      errorPolicy: "all"
    }
  }
});
