// THIS IS A GENERATED FILE! You shouldn't edit it manually. Regenerate it using `yarn generate-graphql`.
import gql from "graphql-tag";
import * as React from "react";
import * as ReactApollo from "react-apollo";
export type Maybe<T> = T | null;
export type Omit<T, K extends keyof T> = Pick<T, Exclude<keyof T, K>>;
/** All built-in and custom scalars, mapped to their actual values */
export type Scalars = {
  ID: string;
  String: string;
  Boolean: boolean;
  Int: number;
  Float: number;
  /** An ISO 8601-encoded datetime */
  ISO8601DateTime: string;
  EntityKey: string;
  FieldKey: string;
  IconName: string;
};

export type Account = {
  __typename?: "Account";
  appUrl: Scalars["String"];
  createdAt: Scalars["ISO8601DateTime"];
  creator: User;
  discarded: Scalars["Boolean"];
  discardedAt?: Maybe<Scalars["ISO8601DateTime"]>;
  id: Scalars["ID"];
  name: Scalars["String"];
  updatedAt: Scalars["ISO8601DateTime"];
};

export type AppQuery = {
  __typename?: "AppQuery";
  /** Get the details of the current account */
  currentAccount: Account;
  /** Get the details of the currently logged in user */
  currentUser: User;
};

export type User = {
  __typename?: "User";
  accounts: Array<Account>;
  authAreaUrl: Scalars["String"];
  confirmed: Scalars["Boolean"];
  createdAt: Scalars["ISO8601DateTime"];
  email: Scalars["String"];
  fullName: Scalars["String"];
  id: Scalars["ID"];
  locked: Scalars["Boolean"];
  preferences: UserPreferences;
  updatedAt: Scalars["ISO8601DateTime"];
};

export type UserPreferences = {
  __typename?: "UserPreferences";
  sidebarExpanded: Scalars["Boolean"];
};
export type SiderInfoQueryVariables = {};

export type SiderInfoQuery = { __typename?: "AppQuery" } & {
  currentUser: { __typename?: "User" } & Pick<User, "email" | "fullName" | "authAreaUrl"> & {
      preferences: { __typename?: "UserPreferences" } & Pick<UserPreferences, "sidebarExpanded">;
    };
};

export const SiderInfoDocument = gql`
  query SiderInfo {
    currentUser {
      email
      fullName
      preferences {
        sidebarExpanded
      }
      authAreaUrl
    }
  }
`;
export type SiderInfoComponentProps = Omit<Omit<ReactApollo.QueryProps<SiderInfoQuery, SiderInfoQueryVariables>, "query">, "variables"> & {
  variables?: SiderInfoQueryVariables;
};

export const SiderInfoComponent = (props: SiderInfoComponentProps) => (
  <ReactApollo.Query<SiderInfoQuery, SiderInfoQueryVariables> query={SiderInfoDocument} {...props} />
);
