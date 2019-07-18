// THIS IS A GENERATED FILE! You shouldn't edit it manually. Regenerate it using `yarn generate-graphql`.
import gql from 'graphql-tag';
import * as React from 'react';
import * as ReactApollo from 'react-apollo';
export type Maybe<T> = T | null;
export type Omit<T, K extends keyof T> = Pick<T, Exclude<keyof T, K>>;
/** All built-in and custom scalars, mapped to their actual values */
export type Scalars = {
  ID: string,
  String: string,
  Boolean: boolean,
  Int: number,
  Float: number,
  /** An ISO 8601-encoded datetime */
  ISO8601DateTime: string,
  /** Untyped JSON output useful for bags of values who's keys or types can't be predicted ahead of time. */
  JSONScalar: any,
  /** Represents textual data as UTF-8 character sequences. This type is most often
   * used by GraphQL to represent free-form human-readable text.
 */
  MutationClientId: any,
};

export type Account = {
  __typename?: 'Account',
  appUrl: Scalars['String'],
  createdAt: Scalars['ISO8601DateTime'],
  creator: User,
  discarded: Scalars['Boolean'],
  discardedAt?: Maybe<Scalars['ISO8601DateTime']>,
  id: Scalars['ID'],
  name: Scalars['String'],
  updatedAt: Scalars['ISO8601DateTime'],
};

/** Attributes for creating or updating an account */
export type AccountAttributes = {
  /** An opaque identifier that will appear on objects created/updated because of
   * this attributes hash, or on errors from it being invalid.
 */
  mutationClientId?: Maybe<Scalars['MutationClientId']>,
  /** Name to set on the account */
  name: Scalars['String'],
};

export type AuthMutation = {
  __typename?: 'AuthMutation',
  createAccount?: Maybe<CreateAccountPayload>,
  discardAccount?: Maybe<DiscardAccountPayload>,
};


export type AuthMutationCreateAccountArgs = {
  account: AccountAttributes
};


export type AuthMutationDiscardAccountArgs = {
  id: Scalars['ID']
};

export type AuthQuery = {
  __typename?: 'AuthQuery',
  accounts: Array<Account>,
  discardedAccounts: Array<Account>,
};

/** Autogenerated return type of CreateAccount */
export type CreateAccountPayload = {
  __typename?: 'CreateAccountPayload',
  account?: Maybe<Account>,
  errors?: Maybe<Array<MutationError>>,
};

/** Autogenerated return type of DiscardAccount */
export type DiscardAccountPayload = {
  __typename?: 'DiscardAccountPayload',
  account?: Maybe<Account>,
  errors?: Maybe<Array<MutationError>>,
};




/** Error object describing a reason why a mutation was unsuccessful, specific to a particular field. */
export type MutationError = {
  __typename?: 'MutationError',
  /** The absolute name of the field relative to the root object that caused this error */
  field: Scalars['String'],
  /** Error message about the field with the field's name in it, like "title can't be blank" */
  fullMessage: Scalars['String'],
  /** Error message about the field without the field's name in it, like "can't be blank" */
  message: Scalars['String'],
  /** The mutation client identifier for the object that caused this error */
  mutationClientId?: Maybe<Scalars['MutationClientId']>,
  /** The relative name of the field on the object (not necessarily the eroot) that cause this error */
  relativeField: Scalars['String'],
};

/** Information about pagination in a connection. */
export type PageInfo = {
  __typename?: 'PageInfo',
  /** When paginating forwards, the cursor to continue. */
  endCursor?: Maybe<Scalars['String']>,
  /** When paginating forwards, are there more items? */
  hasNextPage: Scalars['Boolean'],
  /** When paginating backwards, are there more items? */
  hasPreviousPage: Scalars['Boolean'],
  /** When paginating backwards, the cursor to continue. */
  startCursor?: Maybe<Scalars['String']>,
};

export type ProcessExecution = {
  __typename?: 'ProcessExecution',
  closedTodoCount: Scalars['Int'],
  closestFutureDeadline?: Maybe<Scalars['ISO8601DateTime']>,
  createdAt: Scalars['ISO8601DateTime'],
  creator: User,
  discardedAt: Scalars['ISO8601DateTime'],
  document: Scalars['JSONScalar'],
  id: Scalars['ID'],
  involvedUsers: Array<User>,
  name: Scalars['String'],
  openTodoCount: Scalars['Int'],
  processTemplate?: Maybe<ProcessTemplate>,
  startedAt?: Maybe<Scalars['ISO8601DateTime']>,
  totalTodoCount: Scalars['Int'],
  updatedAt: Scalars['ISO8601DateTime'],
};

/** The connection type for ProcessExecution. */
export type ProcessExecutionConnection = {
  __typename?: 'ProcessExecutionConnection',
  /** A list of edges. */
  edges: Array<ProcessExecutionEdge>,
  /** A list of nodes. */
  nodes: Array<ProcessExecution>,
  /** Information to aid in pagination. */
  pageInfo: PageInfo,
};

/** An edge in a connection. */
export type ProcessExecutionEdge = {
  __typename?: 'ProcessExecutionEdge',
  /** A cursor for use in pagination. */
  cursor: Scalars['String'],
  /** The item at the end of the edge. */
  node?: Maybe<ProcessExecution>,
};

export type ProcessTemplate = {
  __typename?: 'ProcessTemplate',
  createdAt: Scalars['ISO8601DateTime'],
  creator: User,
  discardedAt: Scalars['ISO8601DateTime'],
  document: Scalars['JSONScalar'],
  executionCount: Scalars['Int'],
  id: Scalars['ID'],
  lastExecution?: Maybe<ProcessExecution>,
  name: Scalars['String'],
  updatedAt: Scalars['ISO8601DateTime'],
};

export type Scratchpad = {
  __typename?: 'Scratchpad',
  accessMode: ScratchpadAccessModeEnum,
  closedTodoCount: Scalars['Int'],
  closestFutureDeadline?: Maybe<Scalars['ISO8601DateTime']>,
  createdAt: Scalars['ISO8601DateTime'],
  creator: User,
  discardedAt: Scalars['ISO8601DateTime'],
  document: Scalars['JSONScalar'],
  id: Scalars['ID'],
  name: Scalars['String'],
  openTodoCount: Scalars['Int'],
  totalTodoCount: Scalars['Int'],
  updatedAt: Scalars['ISO8601DateTime'],
};

export const enum ScratchpadAccessModeEnum {
  /** All members of the account can view and edit this scratchpad */
  Public = 'PUBLIC',
  /** Only the creator of the scratchpad can view and edit it with no exceptions. */
  Private = 'PRIVATE'
};

/** The connection type for Scratchpad. */
export type ScratchpadConnection = {
  __typename?: 'ScratchpadConnection',
  /** A list of edges. */
  edges: Array<ScratchpadEdge>,
  /** A list of nodes. */
  nodes: Array<Scratchpad>,
  /** Information to aid in pagination. */
  pageInfo: PageInfo,
};

/** An edge in a connection. */
export type ScratchpadEdge = {
  __typename?: 'ScratchpadEdge',
  /** A cursor for use in pagination. */
  cursor: Scalars['String'],
  /** The item at the end of the edge. */
  node?: Maybe<Scratchpad>,
};

export type TodoFeedItem = {
  __typename?: 'TodoFeedItem',
  createdAt: Scalars['ISO8601DateTime'],
  creator: User,
  id: Scalars['ID'],
  todoSource: TodoFeedItemSourceUnion,
  updatedAt: Scalars['ISO8601DateTime'],
};

/** The connection type for TodoFeedItem. */
export type TodoFeedItemConnection = {
  __typename?: 'TodoFeedItemConnection',
  /** A list of edges. */
  edges: Array<TodoFeedItemEdge>,
  /** A list of nodes. */
  nodes: Array<TodoFeedItem>,
  /** Information to aid in pagination. */
  pageInfo: PageInfo,
};

/** An edge in a connection. */
export type TodoFeedItemEdge = {
  __typename?: 'TodoFeedItemEdge',
  /** A cursor for use in pagination. */
  cursor: Scalars['String'],
  /** The item at the end of the edge. */
  node?: Maybe<TodoFeedItem>,
};

/** Objects which create entries in the todo feed */
export type TodoFeedItemSourceUnion = ProcessExecution | Scratchpad;

export type User = {
  __typename?: 'User',
  accounts: Array<Account>,
  authAreaUrl: Scalars['String'],
  createdAt: Scalars['ISO8601DateTime'],
  email: Scalars['String'],
  fullName?: Maybe<Scalars['String']>,
  id: Scalars['ID'],
  involvedProcessExecutions: ProcessExecutionConnection,
  pendingInvitation: Scalars['Boolean'],
  primaryTextIdentifier: Scalars['String'],
  scratchpads: ScratchpadConnection,
  secondaryTextIdentifier?: Maybe<Scalars['String']>,
  todoFeedItems: TodoFeedItemConnection,
  updatedAt: Scalars['ISO8601DateTime'],
};


export type UserInvolvedProcessExecutionsArgs = {
  after?: Maybe<Scalars['String']>,
  before?: Maybe<Scalars['String']>,
  first?: Maybe<Scalars['Int']>,
  last?: Maybe<Scalars['Int']>
};


export type UserScratchpadsArgs = {
  after?: Maybe<Scalars['String']>,
  before?: Maybe<Scalars['String']>,
  first?: Maybe<Scalars['Int']>,
  last?: Maybe<Scalars['Int']>
};


export type UserTodoFeedItemsArgs = {
  after?: Maybe<Scalars['String']>,
  before?: Maybe<Scalars['String']>,
  first?: Maybe<Scalars['Int']>,
  last?: Maybe<Scalars['Int']>
};
export type AllAccountsQueryVariables = {};


export type AllAccountsQuery = ({ __typename?: 'AuthQuery' } & { accounts: Array<({ __typename?: 'Account' } & Pick<Account, 'id' | 'name' | 'createdAt' | 'appUrl'> & { creator: ({ __typename?: 'User' } & Pick<User, 'fullName'>) })> });

export type DiscardAccountMutationVariables = {
  id: Scalars['ID']
};


export type DiscardAccountMutation = ({ __typename?: 'AuthMutation' } & { discardAccount: Maybe<({ __typename?: 'DiscardAccountPayload' } & { account: Maybe<({ __typename?: 'Account' } & Pick<Account, 'id' | 'name' | 'discarded'>)>, errors: Maybe<Array<({ __typename?: 'MutationError' } & Pick<MutationError, 'field' | 'message'>)>> })> });

export type NewAccountMutationVariables = {
  account: AccountAttributes
};


export type NewAccountMutation = ({ __typename?: 'AuthMutation' } & { createAccount: Maybe<({ __typename?: 'CreateAccountPayload' } & { account: Maybe<({ __typename?: 'Account' } & Pick<Account, 'id' | 'name' | 'appUrl'>)>, errors: Maybe<Array<({ __typename?: 'MutationError' } & Pick<MutationError, 'field' | 'relativeField' | 'message' | 'fullMessage' | 'mutationClientId'>)>> })> });

export const AllAccountsDocument = gql`
    query AllAccounts {
  accounts {
    id
    name
    createdAt
    appUrl
    creator {
      fullName
    }
  }
}
    `;
export type AllAccountsComponentProps = Omit<ReactApollo.QueryProps<AllAccountsQuery, AllAccountsQueryVariables>, 'query'>;

    export const AllAccountsComponent = (props: AllAccountsComponentProps) => (
      <ReactApollo.Query<AllAccountsQuery, AllAccountsQueryVariables> query={AllAccountsDocument} {...props} />
    );
    
export const DiscardAccountDocument = gql`
    mutation DiscardAccount($id: ID!) {
  discardAccount(id: $id) {
    account {
      id
      name
      discarded
    }
    errors {
      field
      message
    }
  }
}
    `;
export type DiscardAccountMutationFn = ReactApollo.MutationFn<DiscardAccountMutation, DiscardAccountMutationVariables>;
export type DiscardAccountComponentProps = Omit<ReactApollo.MutationProps<DiscardAccountMutation, DiscardAccountMutationVariables>, 'mutation'>;

    export const DiscardAccountComponent = (props: DiscardAccountComponentProps) => (
      <ReactApollo.Mutation<DiscardAccountMutation, DiscardAccountMutationVariables> mutation={DiscardAccountDocument} {...props} />
    );
    
export const NewAccountDocument = gql`
    mutation NewAccount($account: AccountAttributes!) {
  createAccount(account: $account) {
    account {
      id
      name
      appUrl
    }
    errors {
      field
      relativeField
      message
      fullMessage
      mutationClientId
    }
  }
}
    `;
export type NewAccountMutationFn = ReactApollo.MutationFn<NewAccountMutation, NewAccountMutationVariables>;
export type NewAccountComponentProps = Omit<ReactApollo.MutationProps<NewAccountMutation, NewAccountMutationVariables>, 'mutation'>;

    export const NewAccountComponent = (props: NewAccountComponentProps) => (
      <ReactApollo.Mutation<NewAccountMutation, NewAccountMutationVariables> mutation={NewAccountDocument} {...props} />
    );
    