// THIS IS A GENERATED FILE! You shouldn't edit it manually. Regenerate it using `yarn generate-graphql`.
import gql from 'graphql-tag';
import * as React from 'react';
import * as ApolloReactCommon from '@apollo/react-common';
import * as ApolloReactComponents from '@apollo/react-components';
import * as ApolloReactHooks from '@apollo/react-hooks';
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
  /** 
 * Represents textual data as UTF-8 character sequences. This type is most often
   * used by GraphQL to represent free-form human-readable text.
 **/
  MutationClientId: any,
};

export type Account = {
   __typename: 'Account',
  appUrl: Scalars['String'],
  businessEpoch: Scalars['ISO8601DateTime'],
  businessLines: Array<BusinessLine>,
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
  /** 
 * An opaque identifier that will appear on objects created/updated because of
   * this attributes hash, or on errors from it being invalid.
 **/
  mutationClientId?: Maybe<Scalars['MutationClientId']>,
  /** Name to set on the account */
  name: Scalars['String'],
  /** Date at which the business started doing business */
  businessEpoch?: Maybe<Scalars['ISO8601DateTime']>,
};

export type AppMutation = {
   __typename: 'AppMutation',
  attachDirectUploadedFile?: Maybe<AttachDirectUploadedFilePayload>,
  attachRemoteUrl?: Maybe<AttachRemoteUrlPayload>,
  completeFacebookAdAccountSetup?: Maybe<CompleteFacebookAdAccountSetupPayload>,
  completeGoogleAnalyticsSetup?: Maybe<CompleteGoogleAnalyticsSetupPayload>,
  connectPlaid?: Maybe<ConnectPlaidPayload>,
  connectShopify?: Maybe<ConnectShopifyPayload>,
  discardConnection?: Maybe<DiscardConnectionPayload>,
  inviteUser?: Maybe<InviteUserPayload>,
  restartConnectionSync?: Maybe<RestartConnectionSyncPayload>,
  setConnectionEnabled?: Maybe<SetConnectionEnabledPayload>,
  syncConnectionNow?: Maybe<SyncConnectionNowPayload>,
  updateAccount?: Maybe<UpdateAccountPayload>,
};


export type AppMutationAttachDirectUploadedFileArgs = {
  directUploadSignedId: Scalars['String'],
  attachmentContainerId: Scalars['ID'],
  attachmentContainerType: AttachmentContainerEnum
};


export type AppMutationAttachRemoteUrlArgs = {
  url: Scalars['String'],
  attachmentContainerId: Scalars['ID'],
  attachmentContainerType: AttachmentContainerEnum
};


export type AppMutationCompleteFacebookAdAccountSetupArgs = {
  facebookAdAccountId: Scalars['ID'],
  selectedFbAccountId: Scalars['String']
};


export type AppMutationCompleteGoogleAnalyticsSetupArgs = {
  credentialId: Scalars['ID'],
  viewId: Scalars['String']
};


export type AppMutationConnectPlaidArgs = {
  publicToken: Scalars['String']
};


export type AppMutationConnectShopifyArgs = {
  apiKey: Scalars['String'],
  password: Scalars['String'],
  domain: Scalars['String']
};


export type AppMutationDiscardConnectionArgs = {
  connectionId: Scalars['ID']
};


export type AppMutationInviteUserArgs = {
  user: UserInviteAttributes
};


export type AppMutationRestartConnectionSyncArgs = {
  connectionId: Scalars['ID']
};


export type AppMutationSetConnectionEnabledArgs = {
  connectionId: Scalars['ID'],
  enabled: Scalars['Boolean']
};


export type AppMutationSyncConnectionNowArgs = {
  connectionId: Scalars['ID']
};


export type AppMutationUpdateAccountArgs = {
  attributes: AccountAttributes
};

export type AppQuery = {
   __typename: 'AppQuery',
  /** Get all the Facebook ad accounts available for a given unconfigured access token during setup */
  availableFacebookAdAccounts: AvailableFacebookAdAccountConnection,
  /** Get all the connections for all integrations for the current account */
  connections: Array<Connectionobj>,
  /** Get the details of the current account */
  currentAccount: Account,
  /** Get the details of the currently logged in user */
  currentUser: User,
  /** Get a JWT token for the current user useful for passing to other services */
  currentUserAuthToken: Scalars['String'],
  /** Get all the Facebook Ad accounts configured for the current account */
  facebookAdAccounts: FacebookAdAccountConnection,
  /** Get all the Google Analytics accounts configured for the current account */
  googleAnalyticsCredentials: GoogleAnalyticsCredentialConnection,
  /** Get all the google analytics views for a given credential */
  googleAnalyticsViews: GoogleAnalyticsViewConnection,
  /** Get all the Plaid connections for the current account */
  plaidItems: PlaidItemConnection,
  /** Get all the Shopify Shop connections for the current account */
  shopifyShops: ShopifyShopConnection,
  /** Get all the active users in the current account */
  users: UserConnection,
  /** Get a datastructure describing all the available models and fields available in the Superpro data model */
  warehouseIntrospection: WarehouseIntrospection,
  /** Execute a query against the Superpro data model */
  warehouseQuery: WarehouseQueryResult,
};


export type AppQueryAvailableFacebookAdAccountsArgs = {
  after?: Maybe<Scalars['String']>,
  before?: Maybe<Scalars['String']>,
  first?: Maybe<Scalars['Int']>,
  last?: Maybe<Scalars['Int']>,
  facebookAdAccountId: Scalars['ID']
};


export type AppQueryFacebookAdAccountsArgs = {
  after?: Maybe<Scalars['String']>,
  before?: Maybe<Scalars['String']>,
  first?: Maybe<Scalars['Int']>,
  last?: Maybe<Scalars['Int']>
};


export type AppQueryGoogleAnalyticsCredentialsArgs = {
  after?: Maybe<Scalars['String']>,
  before?: Maybe<Scalars['String']>,
  first?: Maybe<Scalars['Int']>,
  last?: Maybe<Scalars['Int']>
};


export type AppQueryGoogleAnalyticsViewsArgs = {
  after?: Maybe<Scalars['String']>,
  before?: Maybe<Scalars['String']>,
  first?: Maybe<Scalars['Int']>,
  last?: Maybe<Scalars['Int']>,
  credentialId: Scalars['ID']
};


export type AppQueryPlaidItemsArgs = {
  after?: Maybe<Scalars['String']>,
  before?: Maybe<Scalars['String']>,
  first?: Maybe<Scalars['Int']>,
  last?: Maybe<Scalars['Int']>
};


export type AppQueryShopifyShopsArgs = {
  after?: Maybe<Scalars['String']>,
  before?: Maybe<Scalars['String']>,
  first?: Maybe<Scalars['Int']>,
  last?: Maybe<Scalars['Int']>
};


export type AppQueryUsersArgs = {
  after?: Maybe<Scalars['String']>,
  before?: Maybe<Scalars['String']>,
  first?: Maybe<Scalars['Int']>,
  last?: Maybe<Scalars['Int']>
};


export type AppQueryWarehouseQueryArgs = {
  query: Scalars['JSONScalar'],
  pivot?: Maybe<Scalars['JSONScalar']>
};

/** Autogenerated return type of AttachDirectUploadedFile */
export type AttachDirectUploadedFilePayload = {
   __typename: 'AttachDirectUploadedFilePayload',
  attachment?: Maybe<Attachment>,
  errors?: Maybe<Array<Scalars['String']>>,
};

export type Attachment = {
   __typename: 'Attachment',
  bytesize: Scalars['Int'],
  contentType: Scalars['String'],
  filename: Scalars['String'],
  id: Scalars['ID'],
  url: Scalars['String'],
};

export const enum AttachmentContainerEnum {
  /** Not yet implemented */
  NotImplemented = 'NOT_IMPLEMENTED'
};

/** Autogenerated return type of AttachRemoteUrl */
export type AttachRemoteUrlPayload = {
   __typename: 'AttachRemoteUrlPayload',
  attachment?: Maybe<Attachment>,
  errors?: Maybe<Array<Scalars['String']>>,
};

export type AvailableFacebookAdAccount = {
   __typename: 'AvailableFacebookAdAccount',
  accountStatus: Scalars['String'],
  age: Scalars['String'],
  alreadySetup: Scalars['Boolean'],
  currency: Scalars['String'],
  id: Scalars['String'],
  name: Scalars['String'],
};

/** The connection type for AvailableFacebookAdAccount. */
export type AvailableFacebookAdAccountConnection = {
   __typename: 'AvailableFacebookAdAccountConnection',
  /** A list of edges. */
  edges: Array<AvailableFacebookAdAccountEdge>,
  /** A list of nodes. */
  nodes: Array<AvailableFacebookAdAccount>,
  /** Information to aid in pagination. */
  pageInfo: PageInfo,
};

/** An edge in a connection. */
export type AvailableFacebookAdAccountEdge = {
   __typename: 'AvailableFacebookAdAccountEdge',
  /** A cursor for use in pagination. */
  cursor: Scalars['String'],
  /** The item at the end of the edge. */
  node?: Maybe<AvailableFacebookAdAccount>,
};

export type BusinessLine = {
   __typename: 'BusinessLine',
  id: Scalars['ID'],
  name: Scalars['String'],
};

/** Autogenerated return type of CompleteFacebookAdAccountSetup */
export type CompleteFacebookAdAccountSetupPayload = {
   __typename: 'CompleteFacebookAdAccountSetupPayload',
  facebookAdAccount?: Maybe<FacebookAdAccount>,
};

/** Autogenerated return type of CompleteGoogleAnalyticsSetup */
export type CompleteGoogleAnalyticsSetupPayload = {
   __typename: 'CompleteGoogleAnalyticsSetupPayload',
  googleAnalyticsCredential?: Maybe<GoogleAnalyticsCredential>,
};

/** Objects which may be connected to the system */
export type ConnectionIntegrationUnion = PlaidItem | ShopifyShop | GoogleAnalyticsCredential | FacebookAdAccount;

export type Connectionobj = {
   __typename: 'Connectionobj',
  createdAt: Scalars['ISO8601DateTime'],
  discardedAt?: Maybe<Scalars['ISO8601DateTime']>,
  displayName: Scalars['String'],
  enabled: Scalars['Boolean'],
  id: Scalars['ID'],
  integration: ConnectionIntegrationUnion,
  supportsSync: Scalars['Boolean'],
  supportsTest: Scalars['Boolean'],
  syncAttempts: SyncAttemptConnection,
  updatedAt: Scalars['ISO8601DateTime'],
};


export type ConnectionobjSyncAttemptsArgs = {
  after?: Maybe<Scalars['String']>,
  before?: Maybe<Scalars['String']>,
  first?: Maybe<Scalars['Int']>,
  last?: Maybe<Scalars['Int']>
};

/** Autogenerated return type of ConnectPlaid */
export type ConnectPlaidPayload = {
   __typename: 'ConnectPlaidPayload',
  errors?: Maybe<Array<Scalars['String']>>,
  plaidItem?: Maybe<PlaidItem>,
};

/** Autogenerated return type of ConnectShopify */
export type ConnectShopifyPayload = {
   __typename: 'ConnectShopifyPayload',
  errors?: Maybe<Array<Scalars['String']>>,
  shopifyShop?: Maybe<ShopifyShop>,
};

/** Autogenerated return type of DiscardConnection */
export type DiscardConnectionPayload = {
   __typename: 'DiscardConnectionPayload',
  connection?: Maybe<Connectionobj>,
  errors?: Maybe<Array<Scalars['String']>>,
};

export type FacebookAdAccount = {
   __typename: 'FacebookAdAccount',
  configured: Scalars['String'],
  fbAccountId: Scalars['String'],
  fbAccountName: Scalars['String'],
  grantorId: Scalars['String'],
  grantorName: Scalars['String'],
  id: Scalars['String'],
};

/** The connection type for FacebookAdAccount. */
export type FacebookAdAccountConnection = {
   __typename: 'FacebookAdAccountConnection',
  /** A list of edges. */
  edges: Array<FacebookAdAccountEdge>,
  /** A list of nodes. */
  nodes: Array<FacebookAdAccount>,
  /** Information to aid in pagination. */
  pageInfo: PageInfo,
};

/** An edge in a connection. */
export type FacebookAdAccountEdge = {
   __typename: 'FacebookAdAccountEdge',
  /** A cursor for use in pagination. */
  cursor: Scalars['String'],
  /** The item at the end of the edge. */
  node?: Maybe<FacebookAdAccount>,
};

export type GoogleAnalyticsCredential = {
   __typename: 'GoogleAnalyticsCredential',
  accountId: Scalars['String'],
  accountName: Scalars['String'],
  configured: Scalars['String'],
  grantorEmail: Scalars['String'],
  grantorName: Scalars['String'],
  id: Scalars['String'],
  propertyId: Scalars['String'],
  propertyName: Scalars['String'],
  viewId: Scalars['String'],
  viewName: Scalars['String'],
};

/** The connection type for GoogleAnalyticsCredential. */
export type GoogleAnalyticsCredentialConnection = {
   __typename: 'GoogleAnalyticsCredentialConnection',
  /** A list of edges. */
  edges: Array<GoogleAnalyticsCredentialEdge>,
  /** A list of nodes. */
  nodes: Array<GoogleAnalyticsCredential>,
  /** Information to aid in pagination. */
  pageInfo: PageInfo,
};

/** An edge in a connection. */
export type GoogleAnalyticsCredentialEdge = {
   __typename: 'GoogleAnalyticsCredentialEdge',
  /** A cursor for use in pagination. */
  cursor: Scalars['String'],
  /** The item at the end of the edge. */
  node?: Maybe<GoogleAnalyticsCredential>,
};

export type GoogleAnalyticsView = {
   __typename: 'GoogleAnalyticsView',
  accountId: Scalars['String'],
  accountName: Scalars['String'],
  alreadySetup: Scalars['Boolean'],
  id: Scalars['String'],
  name: Scalars['String'],
  propertyId: Scalars['String'],
  propertyName: Scalars['String'],
};

/** The connection type for GoogleAnalyticsView. */
export type GoogleAnalyticsViewConnection = {
   __typename: 'GoogleAnalyticsViewConnection',
  /** A list of edges. */
  edges: Array<GoogleAnalyticsViewEdge>,
  /** A list of nodes. */
  nodes: Array<GoogleAnalyticsView>,
  /** Information to aid in pagination. */
  pageInfo: PageInfo,
};

/** An edge in a connection. */
export type GoogleAnalyticsViewEdge = {
   __typename: 'GoogleAnalyticsViewEdge',
  /** A cursor for use in pagination. */
  cursor: Scalars['String'],
  /** The item at the end of the edge. */
  node?: Maybe<GoogleAnalyticsView>,
};

/** Autogenerated return type of InviteUser */
export type InviteUserPayload = {
   __typename: 'InviteUserPayload',
  errors?: Maybe<Array<MutationError>>,
  success: Scalars['Boolean'],
};




/** Error object describing a reason why a mutation was unsuccessful, specific to a particular field. */
export type MutationError = {
   __typename: 'MutationError',
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
   __typename: 'PageInfo',
  /** When paginating forwards, the cursor to continue. */
  endCursor?: Maybe<Scalars['String']>,
  /** When paginating forwards, are there more items? */
  hasNextPage: Scalars['Boolean'],
  /** When paginating backwards, are there more items? */
  hasPreviousPage: Scalars['Boolean'],
  /** When paginating backwards, the cursor to continue. */
  startCursor?: Maybe<Scalars['String']>,
};

export type PlaidItem = {
   __typename: 'PlaidItem',
  accountId: Scalars['String'],
  accounts: Array<PlaidItemAccount>,
  createdAt: Scalars['ISO8601DateTime'],
  creator: User,
  id: Scalars['ID'],
  updatedAt: Scalars['ISO8601DateTime'],
};

export type PlaidItemAccount = {
   __typename: 'PlaidItemAccount',
  createdAt: Scalars['ISO8601DateTime'],
  id: Scalars['ID'],
  name: Scalars['String'],
  subtype: Scalars['String'],
  type: Scalars['String'],
};

/** The connection type for PlaidItem. */
export type PlaidItemConnection = {
   __typename: 'PlaidItemConnection',
  /** A list of edges. */
  edges: Array<PlaidItemEdge>,
  /** A list of nodes. */
  nodes: Array<PlaidItem>,
  /** Information to aid in pagination. */
  pageInfo: PageInfo,
};

/** An edge in a connection. */
export type PlaidItemEdge = {
   __typename: 'PlaidItemEdge',
  /** A cursor for use in pagination. */
  cursor: Scalars['String'],
  /** The item at the end of the edge. */
  node?: Maybe<PlaidItem>,
};

/** Autogenerated return type of RestartConnectionSync */
export type RestartConnectionSyncPayload = {
   __typename: 'RestartConnectionSyncPayload',
  connection?: Maybe<Connectionobj>,
  errors?: Maybe<Array<Scalars['String']>>,
};

/** Autogenerated return type of SetConnectionEnabled */
export type SetConnectionEnabledPayload = {
   __typename: 'SetConnectionEnabledPayload',
  connection?: Maybe<Connectionobj>,
  errors?: Maybe<Array<Scalars['String']>>,
};

export type ShopifyShop = {
   __typename: 'ShopifyShop',
  apiKey: Scalars['String'],
  connection: Connectionobj,
  createdAt: Scalars['ISO8601DateTime'],
  creator: User,
  id: Scalars['ID'],
  name: Scalars['String'],
  shopId: Scalars['ID'],
  shopifyDomain: Scalars['String'],
  updatedAt: Scalars['ISO8601DateTime'],
};

/** The connection type for ShopifyShop. */
export type ShopifyShopConnection = {
   __typename: 'ShopifyShopConnection',
  /** A list of edges. */
  edges: Array<ShopifyShopEdge>,
  /** A list of nodes. */
  nodes: Array<ShopifyShop>,
  /** Information to aid in pagination. */
  pageInfo: PageInfo,
};

/** An edge in a connection. */
export type ShopifyShopEdge = {
   __typename: 'ShopifyShopEdge',
  /** A cursor for use in pagination. */
  cursor: Scalars['String'],
  /** The item at the end of the edge. */
  node?: Maybe<ShopifyShop>,
};

export type SyncAttempt = {
   __typename: 'SyncAttempt',
  createdAt: Scalars['ISO8601DateTime'],
  failureReason?: Maybe<Scalars['String']>,
  finishedAt?: Maybe<Scalars['ISO8601DateTime']>,
  id: Scalars['ID'],
  startedAt: Scalars['ISO8601DateTime'],
  success?: Maybe<Scalars['Boolean']>,
  updatedAt: Scalars['ISO8601DateTime'],
};

/** The connection type for SyncAttempt. */
export type SyncAttemptConnection = {
   __typename: 'SyncAttemptConnection',
  /** A list of edges. */
  edges: Array<SyncAttemptEdge>,
  /** A list of nodes. */
  nodes: Array<SyncAttempt>,
  /** Information to aid in pagination. */
  pageInfo: PageInfo,
};

/** An edge in a connection. */
export type SyncAttemptEdge = {
   __typename: 'SyncAttemptEdge',
  /** A cursor for use in pagination. */
  cursor: Scalars['String'],
  /** The item at the end of the edge. */
  node?: Maybe<SyncAttempt>,
};

/** Autogenerated return type of SyncConnectionNow */
export type SyncConnectionNowPayload = {
   __typename: 'SyncConnectionNowPayload',
  connection?: Maybe<Connectionobj>,
  errors?: Maybe<Array<Scalars['String']>>,
};

/** Autogenerated return type of UpdateAccount */
export type UpdateAccountPayload = {
   __typename: 'UpdateAccountPayload',
  account?: Maybe<Account>,
  errors?: Maybe<Array<MutationError>>,
};

export type User = {
   __typename: 'User',
  accounts: Array<Account>,
  authAreaUrl: Scalars['String'],
  createdAt: Scalars['ISO8601DateTime'],
  email: Scalars['String'],
  fullName?: Maybe<Scalars['String']>,
  id: Scalars['ID'],
  pendingInvitation: Scalars['Boolean'],
  primaryTextIdentifier: Scalars['String'],
  secondaryTextIdentifier?: Maybe<Scalars['String']>,
  updatedAt: Scalars['ISO8601DateTime'],
};

/** The connection type for User. */
export type UserConnection = {
   __typename: 'UserConnection',
  /** A list of edges. */
  edges: Array<UserEdge>,
  /** A list of nodes. */
  nodes: Array<User>,
  /** Information to aid in pagination. */
  pageInfo: PageInfo,
};

/** An edge in a connection. */
export type UserEdge = {
   __typename: 'UserEdge',
  /** A cursor for use in pagination. */
  cursor: Scalars['String'],
  /** The item at the end of the edge. */
  node?: Maybe<User>,
};

/** Attributes for inviting a new user */
export type UserInviteAttributes = {
  /** 
 * An opaque identifier that will appear on objects created/updated because of
   * this attributes hash, or on errors from it being invalid.
 **/
  mutationClientId?: Maybe<Scalars['MutationClientId']>,
  /** Email to send the invite to */
  email: Scalars['String'],
};

export const enum WarehouseDataTypeEnum {
  Boolean = 'Boolean',
  Currency = 'Currency',
  DateTime = 'DateTime',
  Duration = 'Duration',
  Number = 'Number',
  Percentage = 'Percentage',
  String = 'String',
  Weight = 'Weight'
};

export type WarehouseIntrospection = {
   __typename: 'WarehouseIntrospection',
  factTables: Array<WarehouseIntrospectionFactTable>,
  operators: Array<WarehouseIntrospectionOperator>,
};

export type WarehouseIntrospectionDimensionField = {
   __typename: 'WarehouseIntrospectionDimensionField',
  allowsOperators: Scalars['Boolean'],
  dataType: WarehouseDataTypeEnum,
  fieldLabel: Scalars['String'],
  fieldName: Scalars['String'],
};

export type WarehouseIntrospectionFactTable = {
   __typename: 'WarehouseIntrospectionFactTable',
  dimensionFields: Array<WarehouseIntrospectionDimensionField>,
  globalFilterFields: Array<WarehouseIntrospectionGlobalFilterField>,
  measureFields: Array<WarehouseIntrospectionMeasureField>,
  name: Scalars['String'],
};

export type WarehouseIntrospectionGlobalFilterField = {
   __typename: 'WarehouseIntrospectionGlobalFilterField',
  field: Scalars['String'],
  filterId: Scalars['String'],
};

export type WarehouseIntrospectionMeasureField = {
   __typename: 'WarehouseIntrospectionMeasureField',
  allowsOperators: Scalars['Boolean'],
  dataType: WarehouseDataTypeEnum,
  defaultOperator?: Maybe<Scalars['String']>,
  fieldLabel: Scalars['String'],
  fieldName: Scalars['String'],
  requiresOperators: Scalars['Boolean'],
};

export type WarehouseIntrospectionOperator = {
   __typename: 'WarehouseIntrospectionOperator',
  key: Scalars['String'],
};

export type WarehouseOutputIntrospection = {
   __typename: 'WarehouseOutputIntrospection',
  dimensions: Array<WarehouseOutputIntrospectionDimension>,
  measures: Array<WarehouseOutputIntrospectionMeasure>,
  pivotedMeasures: Array<WarehouseOutputIntrospectionMeasure>,
};

export type WarehouseOutputIntrospectionDimension = {
   __typename: 'WarehouseOutputIntrospectionDimension',
  dataType: WarehouseDataTypeEnum,
  id: Scalars['String'],
  label: Scalars['String'],
  operator?: Maybe<Scalars['String']>,
  sortable: Scalars['Boolean'],
};

export type WarehouseOutputIntrospectionMeasure = {
   __typename: 'WarehouseOutputIntrospectionMeasure',
  dataType: WarehouseDataTypeEnum,
  id: Scalars['String'],
  label: Scalars['String'],
  operator?: Maybe<Scalars['String']>,
  pivotGroupId?: Maybe<Scalars['String']>,
  sortable: Scalars['Boolean'],
};

export type WarehouseQueryResult = {
   __typename: 'WarehouseQueryResult',
  errors?: Maybe<Array<Scalars['String']>>,
  outputIntrospection?: Maybe<WarehouseOutputIntrospection>,
  records?: Maybe<Array<Scalars['JSONScalar']>>,
};

export type SiderInfoQueryVariables = {};


export type SiderInfoQuery = (
  { __typename: 'AppQuery' }
  & { currentUser: (
    { __typename: 'User' }
    & Pick<User, 'email' | 'fullName' | 'authAreaUrl'>
    & { accounts: Array<(
      { __typename: 'Account' }
      & Pick<Account, 'id'>
    )> }
    & UserCardFragment
  ), currentAccount: (
    { __typename: 'Account' }
    & Pick<Account, 'name'>
  ) }
);

export type UserCardFragment = (
  { __typename: 'User' }
  & Pick<User, 'id' | 'email' | 'primaryTextIdentifier'>
);

export type GetAccountForSettingsQueryVariables = {};


export type GetAccountForSettingsQuery = (
  { __typename: 'AppQuery' }
  & { account: (
    { __typename: 'Account' }
    & Pick<Account, 'id' | 'name' | 'businessEpoch'>
  ) }
);

export type UpdateAccountSettingsMutationVariables = {
  attributes: AccountAttributes
};


export type UpdateAccountSettingsMutation = (
  { __typename: 'AppMutation' }
  & { updateAccount: Maybe<(
    { __typename: 'UpdateAccountPayload' }
    & { account: Maybe<(
      { __typename: 'Account' }
      & Pick<Account, 'id' | 'name' | 'businessEpoch'>
    )>, errors: Maybe<Array<(
      { __typename: 'MutationError' }
      & Pick<MutationError, 'fullMessage'>
    )>> }
  )> }
);

export type InviteNewUserMutationVariables = {
  user: UserInviteAttributes
};


export type InviteNewUserMutation = (
  { __typename: 'AppMutation' }
  & { inviteUser: Maybe<(
    { __typename: 'InviteUserPayload' }
    & Pick<InviteUserPayload, 'success'>
    & { errors: Maybe<Array<(
      { __typename: 'MutationError' }
      & Pick<MutationError, 'fullMessage'>
    )>> }
  )> }
);

export type GetUsersForSettingsQueryVariables = {};


export type GetUsersForSettingsQuery = (
  { __typename: 'AppQuery' }
  & { users: (
    { __typename: 'UserConnection' }
    & { nodes: Array<(
      { __typename: 'User' }
      & Pick<User, 'id' | 'fullName' | 'email' | 'pendingInvitation'>
      & UserCardFragment
    )> }
  ) }
);

export type ConnectionIndexEntryFragment = (
  { __typename: 'Connectionobj' }
  & Pick<Connectionobj, 'id' | 'displayName' | 'supportsSync' | 'enabled'>
  & { integration: { __typename: 'PlaidItem' } | (
    { __typename: 'ShopifyShop' }
    & Pick<ShopifyShop, 'id' | 'name' | 'shopifyDomain' | 'shopId'>
  ) | { __typename: 'GoogleAnalyticsCredential' } | { __typename: 'FacebookAdAccount' }, syncAttempts: (
    { __typename: 'SyncAttemptConnection' }
    & { nodes: Array<(
      { __typename: 'SyncAttempt' }
      & Pick<SyncAttempt, 'id' | 'success' | 'startedAt' | 'finishedAt' | 'failureReason'>
    )> }
  ) }
);

export type RestartConnectionSyncMutationVariables = {
  connectionId: Scalars['ID']
};


export type RestartConnectionSyncMutation = (
  { __typename: 'AppMutation' }
  & { restartConnectionSync: Maybe<(
    { __typename: 'RestartConnectionSyncPayload' }
    & Pick<RestartConnectionSyncPayload, 'errors'>
    & { connection: Maybe<(
      { __typename: 'Connectionobj' }
      & Pick<Connectionobj, 'id'>
    )> }
  )> }
);

export type SyncConnectionNowMutationVariables = {
  connectionId: Scalars['ID']
};


export type SyncConnectionNowMutation = (
  { __typename: 'AppMutation' }
  & { syncConnectionNow: Maybe<(
    { __typename: 'SyncConnectionNowPayload' }
    & Pick<SyncConnectionNowPayload, 'errors'>
    & { connection: Maybe<(
      { __typename: 'Connectionobj' }
      & Pick<Connectionobj, 'id'>
    )> }
  )> }
);

export type SetConnectionEnabledMutationVariables = {
  connectionId: Scalars['ID'],
  enabled: Scalars['Boolean']
};


export type SetConnectionEnabledMutation = (
  { __typename: 'AppMutation' }
  & { setConnectionEnabled: Maybe<(
    { __typename: 'SetConnectionEnabledPayload' }
    & Pick<SetConnectionEnabledPayload, 'errors'>
    & { connection: Maybe<(
      { __typename: 'Connectionobj' }
      & Pick<Connectionobj, 'id' | 'enabled'>
    )> }
  )> }
);

export type DiscardConnectionMutationVariables = {
  connectionId: Scalars['ID']
};


export type DiscardConnectionMutation = (
  { __typename: 'AppMutation' }
  & { discardConnection: Maybe<(
    { __typename: 'DiscardConnectionPayload' }
    & Pick<DiscardConnectionPayload, 'errors'>
    & { connection: Maybe<(
      { __typename: 'Connectionobj' }
      & Pick<Connectionobj, 'id'>
    )> }
  )> }
);

export type GetConnectionsIndexPageQueryVariables = {};


export type GetConnectionsIndexPageQuery = (
  { __typename: 'AppQuery' }
  & { connections: Array<(
    { __typename: 'Connectionobj' }
    & Pick<Connectionobj, 'id'>
    & ConnectionIndexEntryFragment
  )> }
);

export type GetFacebookAdAccountsQueryVariables = {
  facebookAdAccountId: Scalars['ID']
};


export type GetFacebookAdAccountsQuery = (
  { __typename: 'AppQuery' }
  & { availableFacebookAdAccounts: (
    { __typename: 'AvailableFacebookAdAccountConnection' }
    & { nodes: Array<(
      { __typename: 'AvailableFacebookAdAccount' }
      & Pick<AvailableFacebookAdAccount, 'id' | 'name' | 'currency' | 'age' | 'alreadySetup'>
    )> }
  ) }
);

export type CompleteFacebookAdAccountSetupMutationVariables = {
  facebookAdAccountId: Scalars['ID'],
  selectedFbAccountId: Scalars['String']
};


export type CompleteFacebookAdAccountSetupMutation = (
  { __typename: 'AppMutation' }
  & { completeFacebookAdAccountSetup: Maybe<(
    { __typename: 'CompleteFacebookAdAccountSetupPayload' }
    & { facebookAdAccount: Maybe<(
      { __typename: 'FacebookAdAccount' }
      & Pick<FacebookAdAccount, 'id'>
    )> }
  )> }
);

export type GetGoogleAnalyticsViewsQueryVariables = {
  credentialId: Scalars['ID']
};


export type GetGoogleAnalyticsViewsQuery = (
  { __typename: 'AppQuery' }
  & { googleAnalyticsViews: (
    { __typename: 'GoogleAnalyticsViewConnection' }
    & { nodes: Array<(
      { __typename: 'GoogleAnalyticsView' }
      & Pick<GoogleAnalyticsView, 'name' | 'id' | 'propertyName' | 'propertyId' | 'accountName' | 'accountId' | 'alreadySetup'>
    )> }
  ) }
);

export type CompleteGoogleAnalyticsSetupMutationVariables = {
  credentialId: Scalars['ID'],
  viewId: Scalars['String']
};


export type CompleteGoogleAnalyticsSetupMutation = (
  { __typename: 'AppMutation' }
  & { completeGoogleAnalyticsSetup: Maybe<(
    { __typename: 'CompleteGoogleAnalyticsSetupPayload' }
    & { googleAnalyticsCredential: Maybe<(
      { __typename: 'GoogleAnalyticsCredential' }
      & Pick<GoogleAnalyticsCredential, 'id'>
    )> }
  )> }
);

export type GoogleAnalyticsConnectionCardContentFragment = (
  { __typename: 'GoogleAnalyticsCredential' }
  & Pick<GoogleAnalyticsCredential, 'id' | 'viewName' | 'propertyName' | 'accountName'>
);

export type PlaidConnectionCardContentFragment = (
  { __typename: 'PlaidItem' }
  & Pick<PlaidItem, 'id'>
  & { accounts: Array<(
    { __typename: 'PlaidItemAccount' }
    & Pick<PlaidItemAccount, 'id' | 'name' | 'type'>
  )> }
);

export type ConnectPlaidMutationVariables = {
  publicToken: Scalars['String']
};


export type ConnectPlaidMutation = (
  { __typename: 'AppMutation' }
  & { connectPlaid: Maybe<(
    { __typename: 'ConnectPlaidPayload' }
    & { plaidItem: Maybe<(
      { __typename: 'PlaidItem' }
      & PlaidConnectionCardContentFragment
    )> }
  )> }
);

export type ConnectShopifyMutationVariables = {
  apiKey: Scalars['String'],
  password: Scalars['String'],
  domain: Scalars['String']
};


export type ConnectShopifyMutation = (
  { __typename: 'AppMutation' }
  & { connectShopify: Maybe<(
    { __typename: 'ConnectShopifyPayload' }
    & Pick<ConnectShopifyPayload, 'errors'>
    & { shopifyShop: Maybe<(
      { __typename: 'ShopifyShop' }
      & Pick<ShopifyShop, 'id'>
    )> }
  )> }
);

export type ReportBuilderPageQueryVariables = {};


export type ReportBuilderPageQuery = (
  { __typename: 'AppQuery' }
  & WarehouseIntrospectionForWarehouseFragment
);

export type WarehouseIntrospectionForWarehouseFragment = (
  { __typename: 'AppQuery' }
  & { warehouseIntrospection: (
    { __typename: 'WarehouseIntrospection' }
    & { factTables: Array<(
      { __typename: 'WarehouseIntrospectionFactTable' }
      & Pick<WarehouseIntrospectionFactTable, 'name'>
      & { measureFields: Array<(
        { __typename: 'WarehouseIntrospectionMeasureField' }
        & Pick<WarehouseIntrospectionMeasureField, 'fieldName' | 'fieldLabel' | 'dataType' | 'allowsOperators' | 'requiresOperators' | 'defaultOperator'>
      )>, dimensionFields: Array<(
        { __typename: 'WarehouseIntrospectionDimensionField' }
        & Pick<WarehouseIntrospectionDimensionField, 'fieldName' | 'fieldLabel' | 'dataType' | 'allowsOperators'>
      )> }
    )>, operators: Array<(
      { __typename: 'WarehouseIntrospectionOperator' }
      & Pick<WarehouseIntrospectionOperator, 'key'>
    )> }
  ) }
);

export type WarehouseQueryQueryVariables = {
  query: Scalars['JSONScalar'],
  pivot?: Maybe<Scalars['JSONScalar']>
};


export type WarehouseQueryQuery = (
  { __typename: 'AppQuery' }
  & { warehouseQuery: (
    { __typename: 'WarehouseQueryResult' }
    & Pick<WarehouseQueryResult, 'records' | 'errors'>
    & { outputIntrospection: Maybe<(
      { __typename: 'WarehouseOutputIntrospection' }
      & { measures: Array<(
        { __typename: 'WarehouseOutputIntrospectionMeasure' }
        & Pick<WarehouseOutputIntrospectionMeasure, 'id' | 'dataType' | 'operator' | 'label' | 'sortable' | 'pivotGroupId'>
      )>, pivotedMeasures: Array<(
        { __typename: 'WarehouseOutputIntrospectionMeasure' }
        & Pick<WarehouseOutputIntrospectionMeasure, 'id' | 'dataType' | 'operator' | 'label' | 'sortable' | 'pivotGroupId'>
      )>, dimensions: Array<(
        { __typename: 'WarehouseOutputIntrospectionDimension' }
        & Pick<WarehouseOutputIntrospectionDimension, 'id' | 'dataType' | 'operator' | 'label' | 'sortable'>
      )> }
    )> }
  ) }
);

export type GetWarehouseGlobalFilterOptionsQueryVariables = {};


export type GetWarehouseGlobalFilterOptionsQuery = (
  { __typename: 'AppQuery' }
  & { warehouseIntrospection: (
    { __typename: 'WarehouseIntrospection' }
    & { factTables: Array<(
      { __typename: 'WarehouseIntrospectionFactTable' }
      & Pick<WarehouseIntrospectionFactTable, 'name'>
      & { globalFilterFields: Array<(
        { __typename: 'WarehouseIntrospectionGlobalFilterField' }
        & Pick<WarehouseIntrospectionGlobalFilterField, 'filterId' | 'field'>
      )> }
    )>, operators: Array<(
      { __typename: 'WarehouseIntrospectionOperator' }
      & Pick<WarehouseIntrospectionOperator, 'key'>
    )> }
  ), currentAccount: (
    { __typename: 'Account' }
    & Pick<Account, 'id'>
    & { businessLines: Array<(
      { __typename: 'BusinessLine' }
      & Pick<BusinessLine, 'id' | 'name'>
    )> }
  ) }
);

export type AttachUploadToContainerMutationVariables = {
  directUploadSignedId: Scalars['String'],
  attachmentContainerId: Scalars['ID'],
  attachmentContainerType: AttachmentContainerEnum
};


export type AttachUploadToContainerMutation = (
  { __typename: 'AppMutation' }
  & { attachDirectUploadedFile: Maybe<(
    { __typename: 'AttachDirectUploadedFilePayload' }
    & Pick<AttachDirectUploadedFilePayload, 'errors'>
    & { attachment: Maybe<(
      { __typename: 'Attachment' }
      & Pick<Attachment, 'id' | 'filename' | 'contentType' | 'bytesize' | 'url'>
    )> }
  )> }
);

export type AttachRemoteUrlToContainerMutationVariables = {
  url: Scalars['String'],
  attachmentContainerId: Scalars['ID'],
  attachmentContainerType: AttachmentContainerEnum
};


export type AttachRemoteUrlToContainerMutation = (
  { __typename: 'AppMutation' }
  & { attachRemoteUrl: Maybe<(
    { __typename: 'AttachRemoteUrlPayload' }
    & Pick<AttachRemoteUrlPayload, 'errors'>
    & { attachment: Maybe<(
      { __typename: 'Attachment' }
      & Pick<Attachment, 'id' | 'filename' | 'contentType' | 'bytesize' | 'url'>
    )> }
  )> }
);

export const UserCardFragmentDoc = gql`
    fragment UserCard on User {
  id
  email
  primaryTextIdentifier
}
    `;
export const ConnectionIndexEntryFragmentDoc = gql`
    fragment ConnectionIndexEntry on Connectionobj {
  id
  displayName
  integration {
    __typename
    ... on ShopifyShop {
      id
      name
      shopifyDomain
      shopId
    }
  }
  supportsSync
  syncAttempts(first: 15) {
    nodes {
      id
      success
      startedAt
      finishedAt
      failureReason
    }
  }
  enabled
}
    `;
export const GoogleAnalyticsConnectionCardContentFragmentDoc = gql`
    fragment GoogleAnalyticsConnectionCardContent on GoogleAnalyticsCredential {
  id
  viewName
  propertyName
  accountName
}
    `;
export const PlaidConnectionCardContentFragmentDoc = gql`
    fragment PlaidConnectionCardContent on PlaidItem {
  id
  accounts {
    id
    name
    type
  }
}
    `;
export const WarehouseIntrospectionForWarehouseFragmentDoc = gql`
    fragment WarehouseIntrospectionForWarehouse on AppQuery {
  warehouseIntrospection {
    factTables {
      name
      measureFields {
        fieldName
        fieldLabel
        dataType
        allowsOperators
        requiresOperators
        defaultOperator
      }
      dimensionFields {
        fieldName
        fieldLabel
        dataType
        allowsOperators
      }
    }
    operators {
      key
    }
  }
}
    `;
export const SiderInfoDocument = gql`
    query SiderInfo {
  currentUser {
    email
    fullName
    authAreaUrl
    ...UserCard
    accounts {
      id
    }
  }
  currentAccount {
    name
  }
}
    ${UserCardFragmentDoc}`;
export type SiderInfoComponentProps = Omit<ApolloReactComponents.QueryComponentOptions<SiderInfoQuery, SiderInfoQueryVariables>, 'query'>;

    export const SiderInfoComponent = (props: SiderInfoComponentProps) => (
      <ApolloReactComponents.Query<SiderInfoQuery, SiderInfoQueryVariables> query={SiderInfoDocument} {...props} />
    );
    

/**
 * __useSiderInfoQuery__
 *
 * To run a query within a React component, call `useSiderInfoQuery` and pass it any options that fit your needs.
 * When your component renders, `useSiderInfoQuery` returns an object from Apollo Client that contains loading, error, and data properties 
 * you can use to render your UI.
 *
 * @param baseOptions options that will be passed into the query, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options;
 *
 * @example
 * const { data, loading, error } = useSiderInfoQuery({
 *   variables: {
 *   },
 * });
 */
export function useSiderInfoQuery(baseOptions?: ApolloReactHooks.QueryHookOptions<SiderInfoQuery, SiderInfoQueryVariables>) {
        return ApolloReactHooks.useQuery<SiderInfoQuery, SiderInfoQueryVariables>(SiderInfoDocument, baseOptions);
      }
export function useSiderInfoLazyQuery(baseOptions?: ApolloReactHooks.LazyQueryHookOptions<SiderInfoQuery, SiderInfoQueryVariables>) {
          return ApolloReactHooks.useLazyQuery<SiderInfoQuery, SiderInfoQueryVariables>(SiderInfoDocument, baseOptions);
        }
export type SiderInfoQueryHookResult = ReturnType<typeof useSiderInfoQuery>;
export type SiderInfoLazyQueryHookResult = ReturnType<typeof useSiderInfoLazyQuery>;
export type SiderInfoQueryResult = ApolloReactCommon.QueryResult<SiderInfoQuery, SiderInfoQueryVariables>;
export const GetAccountForSettingsDocument = gql`
    query GetAccountForSettings {
  account: currentAccount {
    id
    name
    businessEpoch
  }
}
    `;
export type GetAccountForSettingsComponentProps = Omit<ApolloReactComponents.QueryComponentOptions<GetAccountForSettingsQuery, GetAccountForSettingsQueryVariables>, 'query'>;

    export const GetAccountForSettingsComponent = (props: GetAccountForSettingsComponentProps) => (
      <ApolloReactComponents.Query<GetAccountForSettingsQuery, GetAccountForSettingsQueryVariables> query={GetAccountForSettingsDocument} {...props} />
    );
    

/**
 * __useGetAccountForSettingsQuery__
 *
 * To run a query within a React component, call `useGetAccountForSettingsQuery` and pass it any options that fit your needs.
 * When your component renders, `useGetAccountForSettingsQuery` returns an object from Apollo Client that contains loading, error, and data properties 
 * you can use to render your UI.
 *
 * @param baseOptions options that will be passed into the query, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options;
 *
 * @example
 * const { data, loading, error } = useGetAccountForSettingsQuery({
 *   variables: {
 *   },
 * });
 */
export function useGetAccountForSettingsQuery(baseOptions?: ApolloReactHooks.QueryHookOptions<GetAccountForSettingsQuery, GetAccountForSettingsQueryVariables>) {
        return ApolloReactHooks.useQuery<GetAccountForSettingsQuery, GetAccountForSettingsQueryVariables>(GetAccountForSettingsDocument, baseOptions);
      }
export function useGetAccountForSettingsLazyQuery(baseOptions?: ApolloReactHooks.LazyQueryHookOptions<GetAccountForSettingsQuery, GetAccountForSettingsQueryVariables>) {
          return ApolloReactHooks.useLazyQuery<GetAccountForSettingsQuery, GetAccountForSettingsQueryVariables>(GetAccountForSettingsDocument, baseOptions);
        }
export type GetAccountForSettingsQueryHookResult = ReturnType<typeof useGetAccountForSettingsQuery>;
export type GetAccountForSettingsLazyQueryHookResult = ReturnType<typeof useGetAccountForSettingsLazyQuery>;
export type GetAccountForSettingsQueryResult = ApolloReactCommon.QueryResult<GetAccountForSettingsQuery, GetAccountForSettingsQueryVariables>;
export const UpdateAccountSettingsDocument = gql`
    mutation UpdateAccountSettings($attributes: AccountAttributes!) {
  updateAccount(attributes: $attributes) {
    account {
      id
      name
      businessEpoch
    }
    errors {
      fullMessage
    }
  }
}
    `;
export type UpdateAccountSettingsMutationFn = ApolloReactCommon.MutationFunction<UpdateAccountSettingsMutation, UpdateAccountSettingsMutationVariables>;
export type UpdateAccountSettingsComponentProps = Omit<ApolloReactComponents.MutationComponentOptions<UpdateAccountSettingsMutation, UpdateAccountSettingsMutationVariables>, 'mutation'>;

    export const UpdateAccountSettingsComponent = (props: UpdateAccountSettingsComponentProps) => (
      <ApolloReactComponents.Mutation<UpdateAccountSettingsMutation, UpdateAccountSettingsMutationVariables> mutation={UpdateAccountSettingsDocument} {...props} />
    );
    

/**
 * __useUpdateAccountSettingsMutation__
 *
 * To run a mutation, you first call `useUpdateAccountSettingsMutation` within a React component and pass it any options that fit your needs.
 * When your component renders, `useUpdateAccountSettingsMutation` returns a tuple that includes:
 * - A mutate function that you can call at any time to execute the mutation
 * - An object with fields that represent the current status of the mutation's execution
 *
 * @param baseOptions options that will be passed into the mutation, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options-2;
 *
 * @example
 * const [updateAccountSettingsMutation, { data, loading, error }] = useUpdateAccountSettingsMutation({
 *   variables: {
 *      attributes: // value for 'attributes'
 *   },
 * });
 */
export function useUpdateAccountSettingsMutation(baseOptions?: ApolloReactHooks.MutationHookOptions<UpdateAccountSettingsMutation, UpdateAccountSettingsMutationVariables>) {
        return ApolloReactHooks.useMutation<UpdateAccountSettingsMutation, UpdateAccountSettingsMutationVariables>(UpdateAccountSettingsDocument, baseOptions);
      }
export type UpdateAccountSettingsMutationHookResult = ReturnType<typeof useUpdateAccountSettingsMutation>;
export type UpdateAccountSettingsMutationResult = ApolloReactCommon.MutationResult<UpdateAccountSettingsMutation>;
export type UpdateAccountSettingsMutationOptions = ApolloReactCommon.BaseMutationOptions<UpdateAccountSettingsMutation, UpdateAccountSettingsMutationVariables>;
export const InviteNewUserDocument = gql`
    mutation InviteNewUser($user: UserInviteAttributes!) {
  inviteUser(user: $user) {
    success
    errors {
      fullMessage
    }
  }
}
    `;
export type InviteNewUserMutationFn = ApolloReactCommon.MutationFunction<InviteNewUserMutation, InviteNewUserMutationVariables>;
export type InviteNewUserComponentProps = Omit<ApolloReactComponents.MutationComponentOptions<InviteNewUserMutation, InviteNewUserMutationVariables>, 'mutation'>;

    export const InviteNewUserComponent = (props: InviteNewUserComponentProps) => (
      <ApolloReactComponents.Mutation<InviteNewUserMutation, InviteNewUserMutationVariables> mutation={InviteNewUserDocument} {...props} />
    );
    

/**
 * __useInviteNewUserMutation__
 *
 * To run a mutation, you first call `useInviteNewUserMutation` within a React component and pass it any options that fit your needs.
 * When your component renders, `useInviteNewUserMutation` returns a tuple that includes:
 * - A mutate function that you can call at any time to execute the mutation
 * - An object with fields that represent the current status of the mutation's execution
 *
 * @param baseOptions options that will be passed into the mutation, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options-2;
 *
 * @example
 * const [inviteNewUserMutation, { data, loading, error }] = useInviteNewUserMutation({
 *   variables: {
 *      user: // value for 'user'
 *   },
 * });
 */
export function useInviteNewUserMutation(baseOptions?: ApolloReactHooks.MutationHookOptions<InviteNewUserMutation, InviteNewUserMutationVariables>) {
        return ApolloReactHooks.useMutation<InviteNewUserMutation, InviteNewUserMutationVariables>(InviteNewUserDocument, baseOptions);
      }
export type InviteNewUserMutationHookResult = ReturnType<typeof useInviteNewUserMutation>;
export type InviteNewUserMutationResult = ApolloReactCommon.MutationResult<InviteNewUserMutation>;
export type InviteNewUserMutationOptions = ApolloReactCommon.BaseMutationOptions<InviteNewUserMutation, InviteNewUserMutationVariables>;
export const GetUsersForSettingsDocument = gql`
    query GetUsersForSettings {
  users {
    nodes {
      id
      fullName
      email
      pendingInvitation
      ...UserCard
    }
  }
}
    ${UserCardFragmentDoc}`;
export type GetUsersForSettingsComponentProps = Omit<ApolloReactComponents.QueryComponentOptions<GetUsersForSettingsQuery, GetUsersForSettingsQueryVariables>, 'query'>;

    export const GetUsersForSettingsComponent = (props: GetUsersForSettingsComponentProps) => (
      <ApolloReactComponents.Query<GetUsersForSettingsQuery, GetUsersForSettingsQueryVariables> query={GetUsersForSettingsDocument} {...props} />
    );
    

/**
 * __useGetUsersForSettingsQuery__
 *
 * To run a query within a React component, call `useGetUsersForSettingsQuery` and pass it any options that fit your needs.
 * When your component renders, `useGetUsersForSettingsQuery` returns an object from Apollo Client that contains loading, error, and data properties 
 * you can use to render your UI.
 *
 * @param baseOptions options that will be passed into the query, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options;
 *
 * @example
 * const { data, loading, error } = useGetUsersForSettingsQuery({
 *   variables: {
 *   },
 * });
 */
export function useGetUsersForSettingsQuery(baseOptions?: ApolloReactHooks.QueryHookOptions<GetUsersForSettingsQuery, GetUsersForSettingsQueryVariables>) {
        return ApolloReactHooks.useQuery<GetUsersForSettingsQuery, GetUsersForSettingsQueryVariables>(GetUsersForSettingsDocument, baseOptions);
      }
export function useGetUsersForSettingsLazyQuery(baseOptions?: ApolloReactHooks.LazyQueryHookOptions<GetUsersForSettingsQuery, GetUsersForSettingsQueryVariables>) {
          return ApolloReactHooks.useLazyQuery<GetUsersForSettingsQuery, GetUsersForSettingsQueryVariables>(GetUsersForSettingsDocument, baseOptions);
        }
export type GetUsersForSettingsQueryHookResult = ReturnType<typeof useGetUsersForSettingsQuery>;
export type GetUsersForSettingsLazyQueryHookResult = ReturnType<typeof useGetUsersForSettingsLazyQuery>;
export type GetUsersForSettingsQueryResult = ApolloReactCommon.QueryResult<GetUsersForSettingsQuery, GetUsersForSettingsQueryVariables>;
export const RestartConnectionSyncDocument = gql`
    mutation RestartConnectionSync($connectionId: ID!) {
  restartConnectionSync(connectionId: $connectionId) {
    connection {
      id
    }
    errors
  }
}
    `;
export type RestartConnectionSyncMutationFn = ApolloReactCommon.MutationFunction<RestartConnectionSyncMutation, RestartConnectionSyncMutationVariables>;
export type RestartConnectionSyncComponentProps = Omit<ApolloReactComponents.MutationComponentOptions<RestartConnectionSyncMutation, RestartConnectionSyncMutationVariables>, 'mutation'>;

    export const RestartConnectionSyncComponent = (props: RestartConnectionSyncComponentProps) => (
      <ApolloReactComponents.Mutation<RestartConnectionSyncMutation, RestartConnectionSyncMutationVariables> mutation={RestartConnectionSyncDocument} {...props} />
    );
    

/**
 * __useRestartConnectionSyncMutation__
 *
 * To run a mutation, you first call `useRestartConnectionSyncMutation` within a React component and pass it any options that fit your needs.
 * When your component renders, `useRestartConnectionSyncMutation` returns a tuple that includes:
 * - A mutate function that you can call at any time to execute the mutation
 * - An object with fields that represent the current status of the mutation's execution
 *
 * @param baseOptions options that will be passed into the mutation, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options-2;
 *
 * @example
 * const [restartConnectionSyncMutation, { data, loading, error }] = useRestartConnectionSyncMutation({
 *   variables: {
 *      connectionId: // value for 'connectionId'
 *   },
 * });
 */
export function useRestartConnectionSyncMutation(baseOptions?: ApolloReactHooks.MutationHookOptions<RestartConnectionSyncMutation, RestartConnectionSyncMutationVariables>) {
        return ApolloReactHooks.useMutation<RestartConnectionSyncMutation, RestartConnectionSyncMutationVariables>(RestartConnectionSyncDocument, baseOptions);
      }
export type RestartConnectionSyncMutationHookResult = ReturnType<typeof useRestartConnectionSyncMutation>;
export type RestartConnectionSyncMutationResult = ApolloReactCommon.MutationResult<RestartConnectionSyncMutation>;
export type RestartConnectionSyncMutationOptions = ApolloReactCommon.BaseMutationOptions<RestartConnectionSyncMutation, RestartConnectionSyncMutationVariables>;
export const SyncConnectionNowDocument = gql`
    mutation SyncConnectionNow($connectionId: ID!) {
  syncConnectionNow(connectionId: $connectionId) {
    connection {
      id
    }
    errors
  }
}
    `;
export type SyncConnectionNowMutationFn = ApolloReactCommon.MutationFunction<SyncConnectionNowMutation, SyncConnectionNowMutationVariables>;
export type SyncConnectionNowComponentProps = Omit<ApolloReactComponents.MutationComponentOptions<SyncConnectionNowMutation, SyncConnectionNowMutationVariables>, 'mutation'>;

    export const SyncConnectionNowComponent = (props: SyncConnectionNowComponentProps) => (
      <ApolloReactComponents.Mutation<SyncConnectionNowMutation, SyncConnectionNowMutationVariables> mutation={SyncConnectionNowDocument} {...props} />
    );
    

/**
 * __useSyncConnectionNowMutation__
 *
 * To run a mutation, you first call `useSyncConnectionNowMutation` within a React component and pass it any options that fit your needs.
 * When your component renders, `useSyncConnectionNowMutation` returns a tuple that includes:
 * - A mutate function that you can call at any time to execute the mutation
 * - An object with fields that represent the current status of the mutation's execution
 *
 * @param baseOptions options that will be passed into the mutation, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options-2;
 *
 * @example
 * const [syncConnectionNowMutation, { data, loading, error }] = useSyncConnectionNowMutation({
 *   variables: {
 *      connectionId: // value for 'connectionId'
 *   },
 * });
 */
export function useSyncConnectionNowMutation(baseOptions?: ApolloReactHooks.MutationHookOptions<SyncConnectionNowMutation, SyncConnectionNowMutationVariables>) {
        return ApolloReactHooks.useMutation<SyncConnectionNowMutation, SyncConnectionNowMutationVariables>(SyncConnectionNowDocument, baseOptions);
      }
export type SyncConnectionNowMutationHookResult = ReturnType<typeof useSyncConnectionNowMutation>;
export type SyncConnectionNowMutationResult = ApolloReactCommon.MutationResult<SyncConnectionNowMutation>;
export type SyncConnectionNowMutationOptions = ApolloReactCommon.BaseMutationOptions<SyncConnectionNowMutation, SyncConnectionNowMutationVariables>;
export const SetConnectionEnabledDocument = gql`
    mutation SetConnectionEnabled($connectionId: ID!, $enabled: Boolean!) {
  setConnectionEnabled(connectionId: $connectionId, enabled: $enabled) {
    connection {
      id
      enabled
    }
    errors
  }
}
    `;
export type SetConnectionEnabledMutationFn = ApolloReactCommon.MutationFunction<SetConnectionEnabledMutation, SetConnectionEnabledMutationVariables>;
export type SetConnectionEnabledComponentProps = Omit<ApolloReactComponents.MutationComponentOptions<SetConnectionEnabledMutation, SetConnectionEnabledMutationVariables>, 'mutation'>;

    export const SetConnectionEnabledComponent = (props: SetConnectionEnabledComponentProps) => (
      <ApolloReactComponents.Mutation<SetConnectionEnabledMutation, SetConnectionEnabledMutationVariables> mutation={SetConnectionEnabledDocument} {...props} />
    );
    

/**
 * __useSetConnectionEnabledMutation__
 *
 * To run a mutation, you first call `useSetConnectionEnabledMutation` within a React component and pass it any options that fit your needs.
 * When your component renders, `useSetConnectionEnabledMutation` returns a tuple that includes:
 * - A mutate function that you can call at any time to execute the mutation
 * - An object with fields that represent the current status of the mutation's execution
 *
 * @param baseOptions options that will be passed into the mutation, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options-2;
 *
 * @example
 * const [setConnectionEnabledMutation, { data, loading, error }] = useSetConnectionEnabledMutation({
 *   variables: {
 *      connectionId: // value for 'connectionId'
 *      enabled: // value for 'enabled'
 *   },
 * });
 */
export function useSetConnectionEnabledMutation(baseOptions?: ApolloReactHooks.MutationHookOptions<SetConnectionEnabledMutation, SetConnectionEnabledMutationVariables>) {
        return ApolloReactHooks.useMutation<SetConnectionEnabledMutation, SetConnectionEnabledMutationVariables>(SetConnectionEnabledDocument, baseOptions);
      }
export type SetConnectionEnabledMutationHookResult = ReturnType<typeof useSetConnectionEnabledMutation>;
export type SetConnectionEnabledMutationResult = ApolloReactCommon.MutationResult<SetConnectionEnabledMutation>;
export type SetConnectionEnabledMutationOptions = ApolloReactCommon.BaseMutationOptions<SetConnectionEnabledMutation, SetConnectionEnabledMutationVariables>;
export const DiscardConnectionDocument = gql`
    mutation DiscardConnection($connectionId: ID!) {
  discardConnection(connectionId: $connectionId) {
    connection {
      id
    }
    errors
  }
}
    `;
export type DiscardConnectionMutationFn = ApolloReactCommon.MutationFunction<DiscardConnectionMutation, DiscardConnectionMutationVariables>;
export type DiscardConnectionComponentProps = Omit<ApolloReactComponents.MutationComponentOptions<DiscardConnectionMutation, DiscardConnectionMutationVariables>, 'mutation'>;

    export const DiscardConnectionComponent = (props: DiscardConnectionComponentProps) => (
      <ApolloReactComponents.Mutation<DiscardConnectionMutation, DiscardConnectionMutationVariables> mutation={DiscardConnectionDocument} {...props} />
    );
    

/**
 * __useDiscardConnectionMutation__
 *
 * To run a mutation, you first call `useDiscardConnectionMutation` within a React component and pass it any options that fit your needs.
 * When your component renders, `useDiscardConnectionMutation` returns a tuple that includes:
 * - A mutate function that you can call at any time to execute the mutation
 * - An object with fields that represent the current status of the mutation's execution
 *
 * @param baseOptions options that will be passed into the mutation, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options-2;
 *
 * @example
 * const [discardConnectionMutation, { data, loading, error }] = useDiscardConnectionMutation({
 *   variables: {
 *      connectionId: // value for 'connectionId'
 *   },
 * });
 */
export function useDiscardConnectionMutation(baseOptions?: ApolloReactHooks.MutationHookOptions<DiscardConnectionMutation, DiscardConnectionMutationVariables>) {
        return ApolloReactHooks.useMutation<DiscardConnectionMutation, DiscardConnectionMutationVariables>(DiscardConnectionDocument, baseOptions);
      }
export type DiscardConnectionMutationHookResult = ReturnType<typeof useDiscardConnectionMutation>;
export type DiscardConnectionMutationResult = ApolloReactCommon.MutationResult<DiscardConnectionMutation>;
export type DiscardConnectionMutationOptions = ApolloReactCommon.BaseMutationOptions<DiscardConnectionMutation, DiscardConnectionMutationVariables>;
export const GetConnectionsIndexPageDocument = gql`
    query GetConnectionsIndexPage {
  connections {
    id
    ...ConnectionIndexEntry
  }
}
    ${ConnectionIndexEntryFragmentDoc}`;
export type GetConnectionsIndexPageComponentProps = Omit<ApolloReactComponents.QueryComponentOptions<GetConnectionsIndexPageQuery, GetConnectionsIndexPageQueryVariables>, 'query'>;

    export const GetConnectionsIndexPageComponent = (props: GetConnectionsIndexPageComponentProps) => (
      <ApolloReactComponents.Query<GetConnectionsIndexPageQuery, GetConnectionsIndexPageQueryVariables> query={GetConnectionsIndexPageDocument} {...props} />
    );
    

/**
 * __useGetConnectionsIndexPageQuery__
 *
 * To run a query within a React component, call `useGetConnectionsIndexPageQuery` and pass it any options that fit your needs.
 * When your component renders, `useGetConnectionsIndexPageQuery` returns an object from Apollo Client that contains loading, error, and data properties 
 * you can use to render your UI.
 *
 * @param baseOptions options that will be passed into the query, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options;
 *
 * @example
 * const { data, loading, error } = useGetConnectionsIndexPageQuery({
 *   variables: {
 *   },
 * });
 */
export function useGetConnectionsIndexPageQuery(baseOptions?: ApolloReactHooks.QueryHookOptions<GetConnectionsIndexPageQuery, GetConnectionsIndexPageQueryVariables>) {
        return ApolloReactHooks.useQuery<GetConnectionsIndexPageQuery, GetConnectionsIndexPageQueryVariables>(GetConnectionsIndexPageDocument, baseOptions);
      }
export function useGetConnectionsIndexPageLazyQuery(baseOptions?: ApolloReactHooks.LazyQueryHookOptions<GetConnectionsIndexPageQuery, GetConnectionsIndexPageQueryVariables>) {
          return ApolloReactHooks.useLazyQuery<GetConnectionsIndexPageQuery, GetConnectionsIndexPageQueryVariables>(GetConnectionsIndexPageDocument, baseOptions);
        }
export type GetConnectionsIndexPageQueryHookResult = ReturnType<typeof useGetConnectionsIndexPageQuery>;
export type GetConnectionsIndexPageLazyQueryHookResult = ReturnType<typeof useGetConnectionsIndexPageLazyQuery>;
export type GetConnectionsIndexPageQueryResult = ApolloReactCommon.QueryResult<GetConnectionsIndexPageQuery, GetConnectionsIndexPageQueryVariables>;
export const GetFacebookAdAccountsDocument = gql`
    query GetFacebookAdAccounts($facebookAdAccountId: ID!) {
  availableFacebookAdAccounts(facebookAdAccountId: $facebookAdAccountId) {
    nodes {
      id
      name
      currency
      age
      alreadySetup
    }
  }
}
    `;
export type GetFacebookAdAccountsComponentProps = Omit<ApolloReactComponents.QueryComponentOptions<GetFacebookAdAccountsQuery, GetFacebookAdAccountsQueryVariables>, 'query'> & ({ variables: GetFacebookAdAccountsQueryVariables; skip?: boolean; } | { skip: boolean; });

    export const GetFacebookAdAccountsComponent = (props: GetFacebookAdAccountsComponentProps) => (
      <ApolloReactComponents.Query<GetFacebookAdAccountsQuery, GetFacebookAdAccountsQueryVariables> query={GetFacebookAdAccountsDocument} {...props} />
    );
    

/**
 * __useGetFacebookAdAccountsQuery__
 *
 * To run a query within a React component, call `useGetFacebookAdAccountsQuery` and pass it any options that fit your needs.
 * When your component renders, `useGetFacebookAdAccountsQuery` returns an object from Apollo Client that contains loading, error, and data properties 
 * you can use to render your UI.
 *
 * @param baseOptions options that will be passed into the query, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options;
 *
 * @example
 * const { data, loading, error } = useGetFacebookAdAccountsQuery({
 *   variables: {
 *      facebookAdAccountId: // value for 'facebookAdAccountId'
 *   },
 * });
 */
export function useGetFacebookAdAccountsQuery(baseOptions?: ApolloReactHooks.QueryHookOptions<GetFacebookAdAccountsQuery, GetFacebookAdAccountsQueryVariables>) {
        return ApolloReactHooks.useQuery<GetFacebookAdAccountsQuery, GetFacebookAdAccountsQueryVariables>(GetFacebookAdAccountsDocument, baseOptions);
      }
export function useGetFacebookAdAccountsLazyQuery(baseOptions?: ApolloReactHooks.LazyQueryHookOptions<GetFacebookAdAccountsQuery, GetFacebookAdAccountsQueryVariables>) {
          return ApolloReactHooks.useLazyQuery<GetFacebookAdAccountsQuery, GetFacebookAdAccountsQueryVariables>(GetFacebookAdAccountsDocument, baseOptions);
        }
export type GetFacebookAdAccountsQueryHookResult = ReturnType<typeof useGetFacebookAdAccountsQuery>;
export type GetFacebookAdAccountsLazyQueryHookResult = ReturnType<typeof useGetFacebookAdAccountsLazyQuery>;
export type GetFacebookAdAccountsQueryResult = ApolloReactCommon.QueryResult<GetFacebookAdAccountsQuery, GetFacebookAdAccountsQueryVariables>;
export const CompleteFacebookAdAccountSetupDocument = gql`
    mutation CompleteFacebookAdAccountSetup($facebookAdAccountId: ID!, $selectedFbAccountId: String!) {
  completeFacebookAdAccountSetup(facebookAdAccountId: $facebookAdAccountId, selectedFbAccountId: $selectedFbAccountId) {
    facebookAdAccount {
      id
    }
  }
}
    `;
export type CompleteFacebookAdAccountSetupMutationFn = ApolloReactCommon.MutationFunction<CompleteFacebookAdAccountSetupMutation, CompleteFacebookAdAccountSetupMutationVariables>;
export type CompleteFacebookAdAccountSetupComponentProps = Omit<ApolloReactComponents.MutationComponentOptions<CompleteFacebookAdAccountSetupMutation, CompleteFacebookAdAccountSetupMutationVariables>, 'mutation'>;

    export const CompleteFacebookAdAccountSetupComponent = (props: CompleteFacebookAdAccountSetupComponentProps) => (
      <ApolloReactComponents.Mutation<CompleteFacebookAdAccountSetupMutation, CompleteFacebookAdAccountSetupMutationVariables> mutation={CompleteFacebookAdAccountSetupDocument} {...props} />
    );
    

/**
 * __useCompleteFacebookAdAccountSetupMutation__
 *
 * To run a mutation, you first call `useCompleteFacebookAdAccountSetupMutation` within a React component and pass it any options that fit your needs.
 * When your component renders, `useCompleteFacebookAdAccountSetupMutation` returns a tuple that includes:
 * - A mutate function that you can call at any time to execute the mutation
 * - An object with fields that represent the current status of the mutation's execution
 *
 * @param baseOptions options that will be passed into the mutation, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options-2;
 *
 * @example
 * const [completeFacebookAdAccountSetupMutation, { data, loading, error }] = useCompleteFacebookAdAccountSetupMutation({
 *   variables: {
 *      facebookAdAccountId: // value for 'facebookAdAccountId'
 *      selectedFbAccountId: // value for 'selectedFbAccountId'
 *   },
 * });
 */
export function useCompleteFacebookAdAccountSetupMutation(baseOptions?: ApolloReactHooks.MutationHookOptions<CompleteFacebookAdAccountSetupMutation, CompleteFacebookAdAccountSetupMutationVariables>) {
        return ApolloReactHooks.useMutation<CompleteFacebookAdAccountSetupMutation, CompleteFacebookAdAccountSetupMutationVariables>(CompleteFacebookAdAccountSetupDocument, baseOptions);
      }
export type CompleteFacebookAdAccountSetupMutationHookResult = ReturnType<typeof useCompleteFacebookAdAccountSetupMutation>;
export type CompleteFacebookAdAccountSetupMutationResult = ApolloReactCommon.MutationResult<CompleteFacebookAdAccountSetupMutation>;
export type CompleteFacebookAdAccountSetupMutationOptions = ApolloReactCommon.BaseMutationOptions<CompleteFacebookAdAccountSetupMutation, CompleteFacebookAdAccountSetupMutationVariables>;
export const GetGoogleAnalyticsViewsDocument = gql`
    query GetGoogleAnalyticsViews($credentialId: ID!) {
  googleAnalyticsViews(credentialId: $credentialId) {
    nodes {
      name
      id
      propertyName
      propertyId
      accountName
      accountId
      alreadySetup
    }
  }
}
    `;
export type GetGoogleAnalyticsViewsComponentProps = Omit<ApolloReactComponents.QueryComponentOptions<GetGoogleAnalyticsViewsQuery, GetGoogleAnalyticsViewsQueryVariables>, 'query'> & ({ variables: GetGoogleAnalyticsViewsQueryVariables; skip?: boolean; } | { skip: boolean; });

    export const GetGoogleAnalyticsViewsComponent = (props: GetGoogleAnalyticsViewsComponentProps) => (
      <ApolloReactComponents.Query<GetGoogleAnalyticsViewsQuery, GetGoogleAnalyticsViewsQueryVariables> query={GetGoogleAnalyticsViewsDocument} {...props} />
    );
    

/**
 * __useGetGoogleAnalyticsViewsQuery__
 *
 * To run a query within a React component, call `useGetGoogleAnalyticsViewsQuery` and pass it any options that fit your needs.
 * When your component renders, `useGetGoogleAnalyticsViewsQuery` returns an object from Apollo Client that contains loading, error, and data properties 
 * you can use to render your UI.
 *
 * @param baseOptions options that will be passed into the query, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options;
 *
 * @example
 * const { data, loading, error } = useGetGoogleAnalyticsViewsQuery({
 *   variables: {
 *      credentialId: // value for 'credentialId'
 *   },
 * });
 */
export function useGetGoogleAnalyticsViewsQuery(baseOptions?: ApolloReactHooks.QueryHookOptions<GetGoogleAnalyticsViewsQuery, GetGoogleAnalyticsViewsQueryVariables>) {
        return ApolloReactHooks.useQuery<GetGoogleAnalyticsViewsQuery, GetGoogleAnalyticsViewsQueryVariables>(GetGoogleAnalyticsViewsDocument, baseOptions);
      }
export function useGetGoogleAnalyticsViewsLazyQuery(baseOptions?: ApolloReactHooks.LazyQueryHookOptions<GetGoogleAnalyticsViewsQuery, GetGoogleAnalyticsViewsQueryVariables>) {
          return ApolloReactHooks.useLazyQuery<GetGoogleAnalyticsViewsQuery, GetGoogleAnalyticsViewsQueryVariables>(GetGoogleAnalyticsViewsDocument, baseOptions);
        }
export type GetGoogleAnalyticsViewsQueryHookResult = ReturnType<typeof useGetGoogleAnalyticsViewsQuery>;
export type GetGoogleAnalyticsViewsLazyQueryHookResult = ReturnType<typeof useGetGoogleAnalyticsViewsLazyQuery>;
export type GetGoogleAnalyticsViewsQueryResult = ApolloReactCommon.QueryResult<GetGoogleAnalyticsViewsQuery, GetGoogleAnalyticsViewsQueryVariables>;
export const CompleteGoogleAnalyticsSetupDocument = gql`
    mutation CompleteGoogleAnalyticsSetup($credentialId: ID!, $viewId: String!) {
  completeGoogleAnalyticsSetup(credentialId: $credentialId, viewId: $viewId) {
    googleAnalyticsCredential {
      id
    }
  }
}
    `;
export type CompleteGoogleAnalyticsSetupMutationFn = ApolloReactCommon.MutationFunction<CompleteGoogleAnalyticsSetupMutation, CompleteGoogleAnalyticsSetupMutationVariables>;
export type CompleteGoogleAnalyticsSetupComponentProps = Omit<ApolloReactComponents.MutationComponentOptions<CompleteGoogleAnalyticsSetupMutation, CompleteGoogleAnalyticsSetupMutationVariables>, 'mutation'>;

    export const CompleteGoogleAnalyticsSetupComponent = (props: CompleteGoogleAnalyticsSetupComponentProps) => (
      <ApolloReactComponents.Mutation<CompleteGoogleAnalyticsSetupMutation, CompleteGoogleAnalyticsSetupMutationVariables> mutation={CompleteGoogleAnalyticsSetupDocument} {...props} />
    );
    

/**
 * __useCompleteGoogleAnalyticsSetupMutation__
 *
 * To run a mutation, you first call `useCompleteGoogleAnalyticsSetupMutation` within a React component and pass it any options that fit your needs.
 * When your component renders, `useCompleteGoogleAnalyticsSetupMutation` returns a tuple that includes:
 * - A mutate function that you can call at any time to execute the mutation
 * - An object with fields that represent the current status of the mutation's execution
 *
 * @param baseOptions options that will be passed into the mutation, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options-2;
 *
 * @example
 * const [completeGoogleAnalyticsSetupMutation, { data, loading, error }] = useCompleteGoogleAnalyticsSetupMutation({
 *   variables: {
 *      credentialId: // value for 'credentialId'
 *      viewId: // value for 'viewId'
 *   },
 * });
 */
export function useCompleteGoogleAnalyticsSetupMutation(baseOptions?: ApolloReactHooks.MutationHookOptions<CompleteGoogleAnalyticsSetupMutation, CompleteGoogleAnalyticsSetupMutationVariables>) {
        return ApolloReactHooks.useMutation<CompleteGoogleAnalyticsSetupMutation, CompleteGoogleAnalyticsSetupMutationVariables>(CompleteGoogleAnalyticsSetupDocument, baseOptions);
      }
export type CompleteGoogleAnalyticsSetupMutationHookResult = ReturnType<typeof useCompleteGoogleAnalyticsSetupMutation>;
export type CompleteGoogleAnalyticsSetupMutationResult = ApolloReactCommon.MutationResult<CompleteGoogleAnalyticsSetupMutation>;
export type CompleteGoogleAnalyticsSetupMutationOptions = ApolloReactCommon.BaseMutationOptions<CompleteGoogleAnalyticsSetupMutation, CompleteGoogleAnalyticsSetupMutationVariables>;
export const ConnectPlaidDocument = gql`
    mutation ConnectPlaid($publicToken: String!) {
  connectPlaid(publicToken: $publicToken) {
    plaidItem {
      ...PlaidConnectionCardContent
    }
  }
}
    ${PlaidConnectionCardContentFragmentDoc}`;
export type ConnectPlaidMutationFn = ApolloReactCommon.MutationFunction<ConnectPlaidMutation, ConnectPlaidMutationVariables>;
export type ConnectPlaidComponentProps = Omit<ApolloReactComponents.MutationComponentOptions<ConnectPlaidMutation, ConnectPlaidMutationVariables>, 'mutation'>;

    export const ConnectPlaidComponent = (props: ConnectPlaidComponentProps) => (
      <ApolloReactComponents.Mutation<ConnectPlaidMutation, ConnectPlaidMutationVariables> mutation={ConnectPlaidDocument} {...props} />
    );
    

/**
 * __useConnectPlaidMutation__
 *
 * To run a mutation, you first call `useConnectPlaidMutation` within a React component and pass it any options that fit your needs.
 * When your component renders, `useConnectPlaidMutation` returns a tuple that includes:
 * - A mutate function that you can call at any time to execute the mutation
 * - An object with fields that represent the current status of the mutation's execution
 *
 * @param baseOptions options that will be passed into the mutation, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options-2;
 *
 * @example
 * const [connectPlaidMutation, { data, loading, error }] = useConnectPlaidMutation({
 *   variables: {
 *      publicToken: // value for 'publicToken'
 *   },
 * });
 */
export function useConnectPlaidMutation(baseOptions?: ApolloReactHooks.MutationHookOptions<ConnectPlaidMutation, ConnectPlaidMutationVariables>) {
        return ApolloReactHooks.useMutation<ConnectPlaidMutation, ConnectPlaidMutationVariables>(ConnectPlaidDocument, baseOptions);
      }
export type ConnectPlaidMutationHookResult = ReturnType<typeof useConnectPlaidMutation>;
export type ConnectPlaidMutationResult = ApolloReactCommon.MutationResult<ConnectPlaidMutation>;
export type ConnectPlaidMutationOptions = ApolloReactCommon.BaseMutationOptions<ConnectPlaidMutation, ConnectPlaidMutationVariables>;
export const ConnectShopifyDocument = gql`
    mutation ConnectShopify($apiKey: String!, $password: String!, $domain: String!) {
  connectShopify(apiKey: $apiKey, password: $password, domain: $domain) {
    errors
    shopifyShop {
      id
    }
  }
}
    `;
export type ConnectShopifyMutationFn = ApolloReactCommon.MutationFunction<ConnectShopifyMutation, ConnectShopifyMutationVariables>;
export type ConnectShopifyComponentProps = Omit<ApolloReactComponents.MutationComponentOptions<ConnectShopifyMutation, ConnectShopifyMutationVariables>, 'mutation'>;

    export const ConnectShopifyComponent = (props: ConnectShopifyComponentProps) => (
      <ApolloReactComponents.Mutation<ConnectShopifyMutation, ConnectShopifyMutationVariables> mutation={ConnectShopifyDocument} {...props} />
    );
    

/**
 * __useConnectShopifyMutation__
 *
 * To run a mutation, you first call `useConnectShopifyMutation` within a React component and pass it any options that fit your needs.
 * When your component renders, `useConnectShopifyMutation` returns a tuple that includes:
 * - A mutate function that you can call at any time to execute the mutation
 * - An object with fields that represent the current status of the mutation's execution
 *
 * @param baseOptions options that will be passed into the mutation, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options-2;
 *
 * @example
 * const [connectShopifyMutation, { data, loading, error }] = useConnectShopifyMutation({
 *   variables: {
 *      apiKey: // value for 'apiKey'
 *      password: // value for 'password'
 *      domain: // value for 'domain'
 *   },
 * });
 */
export function useConnectShopifyMutation(baseOptions?: ApolloReactHooks.MutationHookOptions<ConnectShopifyMutation, ConnectShopifyMutationVariables>) {
        return ApolloReactHooks.useMutation<ConnectShopifyMutation, ConnectShopifyMutationVariables>(ConnectShopifyDocument, baseOptions);
      }
export type ConnectShopifyMutationHookResult = ReturnType<typeof useConnectShopifyMutation>;
export type ConnectShopifyMutationResult = ApolloReactCommon.MutationResult<ConnectShopifyMutation>;
export type ConnectShopifyMutationOptions = ApolloReactCommon.BaseMutationOptions<ConnectShopifyMutation, ConnectShopifyMutationVariables>;
export const ReportBuilderPageDocument = gql`
    query ReportBuilderPage {
  ...WarehouseIntrospectionForWarehouse
}
    ${WarehouseIntrospectionForWarehouseFragmentDoc}`;
export type ReportBuilderPageComponentProps = Omit<ApolloReactComponents.QueryComponentOptions<ReportBuilderPageQuery, ReportBuilderPageQueryVariables>, 'query'>;

    export const ReportBuilderPageComponent = (props: ReportBuilderPageComponentProps) => (
      <ApolloReactComponents.Query<ReportBuilderPageQuery, ReportBuilderPageQueryVariables> query={ReportBuilderPageDocument} {...props} />
    );
    

/**
 * __useReportBuilderPageQuery__
 *
 * To run a query within a React component, call `useReportBuilderPageQuery` and pass it any options that fit your needs.
 * When your component renders, `useReportBuilderPageQuery` returns an object from Apollo Client that contains loading, error, and data properties 
 * you can use to render your UI.
 *
 * @param baseOptions options that will be passed into the query, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options;
 *
 * @example
 * const { data, loading, error } = useReportBuilderPageQuery({
 *   variables: {
 *   },
 * });
 */
export function useReportBuilderPageQuery(baseOptions?: ApolloReactHooks.QueryHookOptions<ReportBuilderPageQuery, ReportBuilderPageQueryVariables>) {
        return ApolloReactHooks.useQuery<ReportBuilderPageQuery, ReportBuilderPageQueryVariables>(ReportBuilderPageDocument, baseOptions);
      }
export function useReportBuilderPageLazyQuery(baseOptions?: ApolloReactHooks.LazyQueryHookOptions<ReportBuilderPageQuery, ReportBuilderPageQueryVariables>) {
          return ApolloReactHooks.useLazyQuery<ReportBuilderPageQuery, ReportBuilderPageQueryVariables>(ReportBuilderPageDocument, baseOptions);
        }
export type ReportBuilderPageQueryHookResult = ReturnType<typeof useReportBuilderPageQuery>;
export type ReportBuilderPageLazyQueryHookResult = ReturnType<typeof useReportBuilderPageLazyQuery>;
export type ReportBuilderPageQueryResult = ApolloReactCommon.QueryResult<ReportBuilderPageQuery, ReportBuilderPageQueryVariables>;
export const WarehouseQueryDocument = gql`
    query WarehouseQuery($query: JSONScalar!, $pivot: JSONScalar) {
  warehouseQuery(query: $query, pivot: $pivot) {
    records
    outputIntrospection {
      measures {
        id
        dataType
        operator
        label
        sortable
        pivotGroupId
      }
      pivotedMeasures {
        id
        dataType
        operator
        label
        sortable
        pivotGroupId
      }
      dimensions {
        id
        dataType
        operator
        label
        sortable
      }
    }
    errors
  }
}
    `;
export type WarehouseQueryComponentProps = Omit<ApolloReactComponents.QueryComponentOptions<WarehouseQueryQuery, WarehouseQueryQueryVariables>, 'query'> & ({ variables: WarehouseQueryQueryVariables; skip?: boolean; } | { skip: boolean; });

    export const WarehouseQueryComponent = (props: WarehouseQueryComponentProps) => (
      <ApolloReactComponents.Query<WarehouseQueryQuery, WarehouseQueryQueryVariables> query={WarehouseQueryDocument} {...props} />
    );
    

/**
 * __useWarehouseQueryQuery__
 *
 * To run a query within a React component, call `useWarehouseQueryQuery` and pass it any options that fit your needs.
 * When your component renders, `useWarehouseQueryQuery` returns an object from Apollo Client that contains loading, error, and data properties 
 * you can use to render your UI.
 *
 * @param baseOptions options that will be passed into the query, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options;
 *
 * @example
 * const { data, loading, error } = useWarehouseQueryQuery({
 *   variables: {
 *      query: // value for 'query'
 *      pivot: // value for 'pivot'
 *   },
 * });
 */
export function useWarehouseQueryQuery(baseOptions?: ApolloReactHooks.QueryHookOptions<WarehouseQueryQuery, WarehouseQueryQueryVariables>) {
        return ApolloReactHooks.useQuery<WarehouseQueryQuery, WarehouseQueryQueryVariables>(WarehouseQueryDocument, baseOptions);
      }
export function useWarehouseQueryLazyQuery(baseOptions?: ApolloReactHooks.LazyQueryHookOptions<WarehouseQueryQuery, WarehouseQueryQueryVariables>) {
          return ApolloReactHooks.useLazyQuery<WarehouseQueryQuery, WarehouseQueryQueryVariables>(WarehouseQueryDocument, baseOptions);
        }
export type WarehouseQueryQueryHookResult = ReturnType<typeof useWarehouseQueryQuery>;
export type WarehouseQueryLazyQueryHookResult = ReturnType<typeof useWarehouseQueryLazyQuery>;
export type WarehouseQueryQueryResult = ApolloReactCommon.QueryResult<WarehouseQueryQuery, WarehouseQueryQueryVariables>;
export const GetWarehouseGlobalFilterOptionsDocument = gql`
    query GetWarehouseGlobalFilterOptions {
  warehouseIntrospection {
    factTables {
      name
      globalFilterFields {
        filterId
        field
      }
    }
    operators {
      key
    }
  }
  currentAccount {
    id
    businessLines {
      id
      name
    }
  }
}
    `;
export type GetWarehouseGlobalFilterOptionsComponentProps = Omit<ApolloReactComponents.QueryComponentOptions<GetWarehouseGlobalFilterOptionsQuery, GetWarehouseGlobalFilterOptionsQueryVariables>, 'query'>;

    export const GetWarehouseGlobalFilterOptionsComponent = (props: GetWarehouseGlobalFilterOptionsComponentProps) => (
      <ApolloReactComponents.Query<GetWarehouseGlobalFilterOptionsQuery, GetWarehouseGlobalFilterOptionsQueryVariables> query={GetWarehouseGlobalFilterOptionsDocument} {...props} />
    );
    

/**
 * __useGetWarehouseGlobalFilterOptionsQuery__
 *
 * To run a query within a React component, call `useGetWarehouseGlobalFilterOptionsQuery` and pass it any options that fit your needs.
 * When your component renders, `useGetWarehouseGlobalFilterOptionsQuery` returns an object from Apollo Client that contains loading, error, and data properties 
 * you can use to render your UI.
 *
 * @param baseOptions options that will be passed into the query, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options;
 *
 * @example
 * const { data, loading, error } = useGetWarehouseGlobalFilterOptionsQuery({
 *   variables: {
 *   },
 * });
 */
export function useGetWarehouseGlobalFilterOptionsQuery(baseOptions?: ApolloReactHooks.QueryHookOptions<GetWarehouseGlobalFilterOptionsQuery, GetWarehouseGlobalFilterOptionsQueryVariables>) {
        return ApolloReactHooks.useQuery<GetWarehouseGlobalFilterOptionsQuery, GetWarehouseGlobalFilterOptionsQueryVariables>(GetWarehouseGlobalFilterOptionsDocument, baseOptions);
      }
export function useGetWarehouseGlobalFilterOptionsLazyQuery(baseOptions?: ApolloReactHooks.LazyQueryHookOptions<GetWarehouseGlobalFilterOptionsQuery, GetWarehouseGlobalFilterOptionsQueryVariables>) {
          return ApolloReactHooks.useLazyQuery<GetWarehouseGlobalFilterOptionsQuery, GetWarehouseGlobalFilterOptionsQueryVariables>(GetWarehouseGlobalFilterOptionsDocument, baseOptions);
        }
export type GetWarehouseGlobalFilterOptionsQueryHookResult = ReturnType<typeof useGetWarehouseGlobalFilterOptionsQuery>;
export type GetWarehouseGlobalFilterOptionsLazyQueryHookResult = ReturnType<typeof useGetWarehouseGlobalFilterOptionsLazyQuery>;
export type GetWarehouseGlobalFilterOptionsQueryResult = ApolloReactCommon.QueryResult<GetWarehouseGlobalFilterOptionsQuery, GetWarehouseGlobalFilterOptionsQueryVariables>;
export const AttachUploadToContainerDocument = gql`
    mutation AttachUploadToContainer($directUploadSignedId: String!, $attachmentContainerId: ID!, $attachmentContainerType: AttachmentContainerEnum!) {
  attachDirectUploadedFile(directUploadSignedId: $directUploadSignedId, attachmentContainerId: $attachmentContainerId, attachmentContainerType: $attachmentContainerType) {
    attachment {
      id
      filename
      contentType
      bytesize
      url
    }
    errors
  }
}
    `;
export type AttachUploadToContainerMutationFn = ApolloReactCommon.MutationFunction<AttachUploadToContainerMutation, AttachUploadToContainerMutationVariables>;
export type AttachUploadToContainerComponentProps = Omit<ApolloReactComponents.MutationComponentOptions<AttachUploadToContainerMutation, AttachUploadToContainerMutationVariables>, 'mutation'>;

    export const AttachUploadToContainerComponent = (props: AttachUploadToContainerComponentProps) => (
      <ApolloReactComponents.Mutation<AttachUploadToContainerMutation, AttachUploadToContainerMutationVariables> mutation={AttachUploadToContainerDocument} {...props} />
    );
    

/**
 * __useAttachUploadToContainerMutation__
 *
 * To run a mutation, you first call `useAttachUploadToContainerMutation` within a React component and pass it any options that fit your needs.
 * When your component renders, `useAttachUploadToContainerMutation` returns a tuple that includes:
 * - A mutate function that you can call at any time to execute the mutation
 * - An object with fields that represent the current status of the mutation's execution
 *
 * @param baseOptions options that will be passed into the mutation, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options-2;
 *
 * @example
 * const [attachUploadToContainerMutation, { data, loading, error }] = useAttachUploadToContainerMutation({
 *   variables: {
 *      directUploadSignedId: // value for 'directUploadSignedId'
 *      attachmentContainerId: // value for 'attachmentContainerId'
 *      attachmentContainerType: // value for 'attachmentContainerType'
 *   },
 * });
 */
export function useAttachUploadToContainerMutation(baseOptions?: ApolloReactHooks.MutationHookOptions<AttachUploadToContainerMutation, AttachUploadToContainerMutationVariables>) {
        return ApolloReactHooks.useMutation<AttachUploadToContainerMutation, AttachUploadToContainerMutationVariables>(AttachUploadToContainerDocument, baseOptions);
      }
export type AttachUploadToContainerMutationHookResult = ReturnType<typeof useAttachUploadToContainerMutation>;
export type AttachUploadToContainerMutationResult = ApolloReactCommon.MutationResult<AttachUploadToContainerMutation>;
export type AttachUploadToContainerMutationOptions = ApolloReactCommon.BaseMutationOptions<AttachUploadToContainerMutation, AttachUploadToContainerMutationVariables>;
export const AttachRemoteUrlToContainerDocument = gql`
    mutation AttachRemoteUrlToContainer($url: String!, $attachmentContainerId: ID!, $attachmentContainerType: AttachmentContainerEnum!) {
  attachRemoteUrl(url: $url, attachmentContainerId: $attachmentContainerId, attachmentContainerType: $attachmentContainerType) {
    attachment {
      id
      filename
      contentType
      bytesize
      url
    }
    errors
  }
}
    `;
export type AttachRemoteUrlToContainerMutationFn = ApolloReactCommon.MutationFunction<AttachRemoteUrlToContainerMutation, AttachRemoteUrlToContainerMutationVariables>;
export type AttachRemoteUrlToContainerComponentProps = Omit<ApolloReactComponents.MutationComponentOptions<AttachRemoteUrlToContainerMutation, AttachRemoteUrlToContainerMutationVariables>, 'mutation'>;

    export const AttachRemoteUrlToContainerComponent = (props: AttachRemoteUrlToContainerComponentProps) => (
      <ApolloReactComponents.Mutation<AttachRemoteUrlToContainerMutation, AttachRemoteUrlToContainerMutationVariables> mutation={AttachRemoteUrlToContainerDocument} {...props} />
    );
    

/**
 * __useAttachRemoteUrlToContainerMutation__
 *
 * To run a mutation, you first call `useAttachRemoteUrlToContainerMutation` within a React component and pass it any options that fit your needs.
 * When your component renders, `useAttachRemoteUrlToContainerMutation` returns a tuple that includes:
 * - A mutate function that you can call at any time to execute the mutation
 * - An object with fields that represent the current status of the mutation's execution
 *
 * @param baseOptions options that will be passed into the mutation, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options-2;
 *
 * @example
 * const [attachRemoteUrlToContainerMutation, { data, loading, error }] = useAttachRemoteUrlToContainerMutation({
 *   variables: {
 *      url: // value for 'url'
 *      attachmentContainerId: // value for 'attachmentContainerId'
 *      attachmentContainerType: // value for 'attachmentContainerType'
 *   },
 * });
 */
export function useAttachRemoteUrlToContainerMutation(baseOptions?: ApolloReactHooks.MutationHookOptions<AttachRemoteUrlToContainerMutation, AttachRemoteUrlToContainerMutationVariables>) {
        return ApolloReactHooks.useMutation<AttachRemoteUrlToContainerMutation, AttachRemoteUrlToContainerMutationVariables>(AttachRemoteUrlToContainerDocument, baseOptions);
      }
export type AttachRemoteUrlToContainerMutationHookResult = ReturnType<typeof useAttachRemoteUrlToContainerMutation>;
export type AttachRemoteUrlToContainerMutationResult = ApolloReactCommon.MutationResult<AttachRemoteUrlToContainerMutation>;
export type AttachRemoteUrlToContainerMutationOptions = ApolloReactCommon.BaseMutationOptions<AttachRemoteUrlToContainerMutation, AttachRemoteUrlToContainerMutationVariables>;