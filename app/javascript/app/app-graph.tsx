// THIS IS A GENERATED FILE! You shouldn't edit it manually. Regenerate it using `yarn generate-graphql`.
import gql from "graphql-tag";
import * as React from "react";
import * as ReactApollo from "react-apollo";
import * as ReactApolloHooks from "react-apollo-hooks";
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
  /** Represents textual data as UTF-8 character sequences. This type is most often
   * used by GraphQL to represent free-form human-readable text.
   */
  MutationClientId: any;
  RecurrenceRuleString: string;
};

export type Account = {
  __typename: "Account";
  appUrl: Scalars["String"];
  createdAt: Scalars["ISO8601DateTime"];
  creator: User;
  discarded: Scalars["Boolean"];
  discardedAt?: Maybe<Scalars["ISO8601DateTime"]>;
  id: Scalars["ID"];
  name: Scalars["String"];
  updatedAt: Scalars["ISO8601DateTime"];
};

/** Attributes for creating or updating an account */
export type AccountAttributes = {
  /** An opaque identifier that will appear on objects created/updated because of
   * this attributes hash, or on errors from it being invalid.
   */
  mutationClientId?: Maybe<Scalars["MutationClientId"]>;
  /** Name to set on the account */
  name: Scalars["String"];
};

export type AppMutation = {
  __typename: "AppMutation";
  attachDirectUploadedFile?: Maybe<AttachDirectUploadedFilePayload>;
  attachRemoteUrl?: Maybe<AttachRemoteUrlPayload>;
  completeGoogleAnalyticsSetup?: Maybe<CompleteGoogleAnalyticsSetupPayload>;
  connectPlaid?: Maybe<ConnectPlaidPayload>;
  connectShopify?: Maybe<ConnectShopifyPayload>;
  inviteUser?: Maybe<InviteUserPayload>;
  restartConnectionSync?: Maybe<RestartConnectionSyncPayload>;
  updateAccount?: Maybe<UpdateAccountPayload>;
};

export type AppMutationAttachDirectUploadedFileArgs = {
  directUploadSignedId: Scalars["String"];
  attachmentContainerId: Scalars["ID"];
  attachmentContainerType: AttachmentContainerEnum;
};

export type AppMutationAttachRemoteUrlArgs = {
  url: Scalars["String"];
  attachmentContainerId: Scalars["ID"];
  attachmentContainerType: AttachmentContainerEnum;
};

export type AppMutationCompleteGoogleAnalyticsSetupArgs = {
  credentialId: Scalars["ID"];
  viewId: Scalars["String"];
};

export type AppMutationConnectPlaidArgs = {
  publicToken: Scalars["String"];
};

export type AppMutationConnectShopifyArgs = {
  apiKey: Scalars["String"];
  password: Scalars["String"];
  domain: Scalars["String"];
};

export type AppMutationInviteUserArgs = {
  user: UserInviteAttributes;
};

export type AppMutationRestartConnectionSyncArgs = {
  connectionId: Scalars["ID"];
};

export type AppMutationUpdateAccountArgs = {
  attributes: AccountAttributes;
};

export type AppQuery = {
  __typename: "AppQuery";
  /** Get all the connections for all integrations for the current account */
  connections: ConnectionConnection;
  /** Get the details of the current account */
  currentAccount: Account;
  /** Get the details of the currently logged in user */
  currentUser: User;
  /** Get all the Google Analytics accounts configured for the current account */
  googleAnalyticsCredentials: GoogleAnalyticsCredentialConnection;
  /** Get all the google analytics views for a given credential */
  googleAnalyticsViews: GoogleAnalyticsViewConnection;
  /** Get all the Plaid connections for the current account */
  plaidItems: PlaidItemConnection;
  /** Get all the Shopify Shop connections for the current account */
  shopifyShops: ShopifyShopConnection;
  /** Get all the active users in the current account */
  users: UserConnection;
};

export type AppQueryConnectionsArgs = {
  after?: Maybe<Scalars["String"]>;
  before?: Maybe<Scalars["String"]>;
  first?: Maybe<Scalars["Int"]>;
  last?: Maybe<Scalars["Int"]>;
};

export type AppQueryGoogleAnalyticsCredentialsArgs = {
  after?: Maybe<Scalars["String"]>;
  before?: Maybe<Scalars["String"]>;
  first?: Maybe<Scalars["Int"]>;
  last?: Maybe<Scalars["Int"]>;
};

export type AppQueryGoogleAnalyticsViewsArgs = {
  after?: Maybe<Scalars["String"]>;
  before?: Maybe<Scalars["String"]>;
  first?: Maybe<Scalars["Int"]>;
  last?: Maybe<Scalars["Int"]>;
  credentialId: Scalars["ID"];
};

export type AppQueryPlaidItemsArgs = {
  after?: Maybe<Scalars["String"]>;
  before?: Maybe<Scalars["String"]>;
  first?: Maybe<Scalars["Int"]>;
  last?: Maybe<Scalars["Int"]>;
};

export type AppQueryShopifyShopsArgs = {
  after?: Maybe<Scalars["String"]>;
  before?: Maybe<Scalars["String"]>;
  first?: Maybe<Scalars["Int"]>;
  last?: Maybe<Scalars["Int"]>;
};

export type AppQueryUsersArgs = {
  after?: Maybe<Scalars["String"]>;
  before?: Maybe<Scalars["String"]>;
  first?: Maybe<Scalars["Int"]>;
  last?: Maybe<Scalars["Int"]>;
};

/** Autogenerated return type of AttachDirectUploadedFile */
export type AttachDirectUploadedFilePayload = {
  __typename: "AttachDirectUploadedFilePayload";
  attachment?: Maybe<Attachment>;
  errors?: Maybe<Array<Scalars["String"]>>;
};

export type Attachment = {
  __typename: "Attachment";
  bytesize: Scalars["Int"];
  contentType: Scalars["String"];
  filename: Scalars["String"];
  id: Scalars["ID"];
  url: Scalars["String"];
};

export const enum AttachmentContainerEnum {
  /** Not yet implemented */
  NotImplemented = "NOT_IMPLEMENTED"
}

/** Autogenerated return type of AttachRemoteUrl */
export type AttachRemoteUrlPayload = {
  __typename: "AttachRemoteUrlPayload";
  attachment?: Maybe<Attachment>;
  errors?: Maybe<Array<Scalars["String"]>>;
};

/** Autogenerated return type of CompleteGoogleAnalyticsSetup */
export type CompleteGoogleAnalyticsSetupPayload = {
  __typename: "CompleteGoogleAnalyticsSetupPayload";
  googleAnalyticsCredential?: Maybe<GoogleAnalyticsCredential>;
};

export type Connection = {
  __typename: "Connection";
  createdAt: Scalars["ISO8601DateTime"];
  displayName: Scalars["String"];
  enabled: Scalars["Boolean"];
  id: Scalars["ID"];
  integration: ConnectionIntegrationUnion;
  updatedAt: Scalars["ISO8601DateTime"];
};

/** The connection type for Connection. */
export type ConnectionConnection = {
  __typename: "ConnectionConnection";
  /** A list of edges. */
  edges: Array<ConnectionEdge>;
  /** A list of nodes. */
  nodes: Array<Connection>;
  /** Information to aid in pagination. */
  pageInfo: PageInfo;
};

/** The connection type for Connection. */
export type ConnectionConnectionNodesArgs = {
  after?: Maybe<Scalars["String"]>;
  before?: Maybe<Scalars["String"]>;
  first?: Maybe<Scalars["Int"]>;
  last?: Maybe<Scalars["Int"]>;
};

/** An edge in a connection. */
export type ConnectionEdge = {
  __typename: "ConnectionEdge";
  /** A cursor for use in pagination. */
  cursor: Scalars["String"];
  /** The item at the end of the edge. */
  node?: Maybe<Connection>;
};

/** An edge in a connection. */
export type ConnectionEdgeNodeArgs = {
  after?: Maybe<Scalars["String"]>;
  before?: Maybe<Scalars["String"]>;
  first?: Maybe<Scalars["Int"]>;
  last?: Maybe<Scalars["Int"]>;
};

/** Objects which may be connected to the system */
export type ConnectionIntegrationUnion = PlaidItem | ShopifyShop | GoogleAnalyticsCredential;

/** Autogenerated return type of ConnectPlaid */
export type ConnectPlaidPayload = {
  __typename: "ConnectPlaidPayload";
  errors?: Maybe<Array<Scalars["String"]>>;
  plaidItem?: Maybe<PlaidItem>;
};

/** Autogenerated return type of ConnectShopify */
export type ConnectShopifyPayload = {
  __typename: "ConnectShopifyPayload";
  errors?: Maybe<Array<Scalars["String"]>>;
  shopifyShop?: Maybe<ShopifyShop>;
};

export type GoogleAnalyticsCredential = {
  __typename: "GoogleAnalyticsCredential";
  accountId: Scalars["String"];
  accountName: Scalars["String"];
  configured: Scalars["String"];
  grantorEmail: Scalars["String"];
  grantorName: Scalars["String"];
  id: Scalars["String"];
  propertyId: Scalars["String"];
  propertyName: Scalars["String"];
  viewId: Scalars["String"];
  viewName: Scalars["String"];
};

/** The connection type for GoogleAnalyticsCredential. */
export type GoogleAnalyticsCredentialConnection = {
  __typename: "GoogleAnalyticsCredentialConnection";
  /** A list of edges. */
  edges: Array<GoogleAnalyticsCredentialEdge>;
  /** A list of nodes. */
  nodes: Array<GoogleAnalyticsCredential>;
  /** Information to aid in pagination. */
  pageInfo: PageInfo;
};

/** An edge in a connection. */
export type GoogleAnalyticsCredentialEdge = {
  __typename: "GoogleAnalyticsCredentialEdge";
  /** A cursor for use in pagination. */
  cursor: Scalars["String"];
  /** The item at the end of the edge. */
  node?: Maybe<GoogleAnalyticsCredential>;
};

export type GoogleAnalyticsView = {
  __typename: "GoogleAnalyticsView";
  accountId: Scalars["String"];
  accountName: Scalars["String"];
  alreadySetup: Scalars["Boolean"];
  id: Scalars["String"];
  name: Scalars["String"];
  propertyId: Scalars["String"];
  propertyName: Scalars["String"];
};

/** The connection type for GoogleAnalyticsView. */
export type GoogleAnalyticsViewConnection = {
  __typename: "GoogleAnalyticsViewConnection";
  /** A list of edges. */
  edges: Array<GoogleAnalyticsViewEdge>;
  /** A list of nodes. */
  nodes: Array<GoogleAnalyticsView>;
  /** Information to aid in pagination. */
  pageInfo: PageInfo;
};

/** An edge in a connection. */
export type GoogleAnalyticsViewEdge = {
  __typename: "GoogleAnalyticsViewEdge";
  /** A cursor for use in pagination. */
  cursor: Scalars["String"];
  /** The item at the end of the edge. */
  node?: Maybe<GoogleAnalyticsView>;
};

/** Autogenerated return type of InviteUser */
export type InviteUserPayload = {
  __typename: "InviteUserPayload";
  errors?: Maybe<Array<MutationError>>;
  success: Scalars["Boolean"];
};

/** Error object describing a reason why a mutation was unsuccessful, specific to a particular field. */
export type MutationError = {
  __typename: "MutationError";
  /** The absolute name of the field relative to the root object that caused this error */
  field: Scalars["String"];
  /** Error message about the field with the field's name in it, like "title can't be blank" */
  fullMessage: Scalars["String"];
  /** Error message about the field without the field's name in it, like "can't be blank" */
  message: Scalars["String"];
  /** The mutation client identifier for the object that caused this error */
  mutationClientId?: Maybe<Scalars["MutationClientId"]>;
  /** The relative name of the field on the object (not necessarily the eroot) that cause this error */
  relativeField: Scalars["String"];
};

/** Information about pagination in a connection. */
export type PageInfo = {
  __typename: "PageInfo";
  /** When paginating forwards, the cursor to continue. */
  endCursor?: Maybe<Scalars["String"]>;
  /** When paginating forwards, are there more items? */
  hasNextPage: Scalars["Boolean"];
  /** When paginating backwards, are there more items? */
  hasPreviousPage: Scalars["Boolean"];
  /** When paginating backwards, the cursor to continue. */
  startCursor?: Maybe<Scalars["String"]>;
};

export type PlaidItem = {
  __typename: "PlaidItem";
  accountId: Scalars["String"];
  accounts: Array<PlaidItemAccount>;
  createdAt: Scalars["ISO8601DateTime"];
  creator: User;
  id: Scalars["ID"];
  updatedAt: Scalars["ISO8601DateTime"];
};

export type PlaidItemAccount = {
  __typename: "PlaidItemAccount";
  createdAt: Scalars["ISO8601DateTime"];
  id: Scalars["ID"];
  name: Scalars["String"];
  subtype: Scalars["String"];
  type: Scalars["String"];
};

/** The connection type for PlaidItem. */
export type PlaidItemConnection = {
  __typename: "PlaidItemConnection";
  /** A list of edges. */
  edges: Array<PlaidItemEdge>;
  /** A list of nodes. */
  nodes: Array<PlaidItem>;
  /** Information to aid in pagination. */
  pageInfo: PageInfo;
};

/** An edge in a connection. */
export type PlaidItemEdge = {
  __typename: "PlaidItemEdge";
  /** A cursor for use in pagination. */
  cursor: Scalars["String"];
  /** The item at the end of the edge. */
  node?: Maybe<PlaidItem>;
};

/** Autogenerated return type of RestartConnectionSync */
export type RestartConnectionSyncPayload = {
  __typename: "RestartConnectionSyncPayload";
  connection?: Maybe<Connection>;
  errors?: Maybe<Array<Scalars["String"]>>;
};

export type ShopifyShop = {
  __typename: "ShopifyShop";
  apiKey: Scalars["String"];
  connection: Connection;
  createdAt: Scalars["ISO8601DateTime"];
  creator: User;
  id: Scalars["ID"];
  name: Scalars["String"];
  shopId: Scalars["ID"];
  shopifyDomain: Scalars["String"];
  updatedAt: Scalars["ISO8601DateTime"];
};

/** The connection type for ShopifyShop. */
export type ShopifyShopConnection = {
  __typename: "ShopifyShopConnection";
  /** A list of edges. */
  edges: Array<ShopifyShopEdge>;
  /** A list of nodes. */
  nodes: Array<ShopifyShop>;
  /** Information to aid in pagination. */
  pageInfo: PageInfo;
};

/** An edge in a connection. */
export type ShopifyShopEdge = {
  __typename: "ShopifyShopEdge";
  /** A cursor for use in pagination. */
  cursor: Scalars["String"];
  /** The item at the end of the edge. */
  node?: Maybe<ShopifyShop>;
};

/** Autogenerated return type of UpdateAccount */
export type UpdateAccountPayload = {
  __typename: "UpdateAccountPayload";
  account?: Maybe<Account>;
  errors?: Maybe<Array<MutationError>>;
};

export type User = {
  __typename: "User";
  accounts: Array<Account>;
  authAreaUrl: Scalars["String"];
  createdAt: Scalars["ISO8601DateTime"];
  email: Scalars["String"];
  fullName?: Maybe<Scalars["String"]>;
  id: Scalars["ID"];
  pendingInvitation: Scalars["Boolean"];
  primaryTextIdentifier: Scalars["String"];
  secondaryTextIdentifier?: Maybe<Scalars["String"]>;
  updatedAt: Scalars["ISO8601DateTime"];
};

/** The connection type for User. */
export type UserConnection = {
  __typename: "UserConnection";
  /** A list of edges. */
  edges: Array<UserEdge>;
  /** A list of nodes. */
  nodes: Array<User>;
  /** Information to aid in pagination. */
  pageInfo: PageInfo;
};

/** An edge in a connection. */
export type UserEdge = {
  __typename: "UserEdge";
  /** A cursor for use in pagination. */
  cursor: Scalars["String"];
  /** The item at the end of the edge. */
  node?: Maybe<User>;
};

/** Attributes for inviting a new user */
export type UserInviteAttributes = {
  /** An opaque identifier that will appear on objects created/updated because of
   * this attributes hash, or on errors from it being invalid.
   */
  mutationClientId?: Maybe<Scalars["MutationClientId"]>;
  /** Email to send the invite to */
  email: Scalars["String"];
};
export type SiderInfoQueryVariables = {};

export type SiderInfoQuery = { __typename: "AppQuery" } & {
  currentUser: { __typename: "User" } & Pick<User, "email" | "fullName" | "authAreaUrl"> & UserCardFragment;
};

export type UserCardFragment = { __typename: "User" } & Pick<User, "id" | "email" | "primaryTextIdentifier">;

export type GetAccountForSettingsQueryVariables = {};

export type GetAccountForSettingsQuery = { __typename: "AppQuery" } & { account: { __typename: "Account" } & Pick<Account, "id" | "name"> };

export type UpdateAccountSettingsMutationVariables = {
  attributes: AccountAttributes;
};

export type UpdateAccountSettingsMutation = { __typename: "AppMutation" } & {
  updateAccount: Maybe<
    { __typename: "UpdateAccountPayload" } & {
      account: Maybe<{ __typename: "Account" } & Pick<Account, "id" | "name">>;
      errors: Maybe<Array<{ __typename: "MutationError" } & Pick<MutationError, "fullMessage">>>;
    }
  >;
};

export type GetConnectionsIndexPageQueryVariables = {};

export type GetConnectionsIndexPageQuery = { __typename: "AppQuery" } & {
  plaidItems: { __typename: "PlaidItemConnection" } & { nodes: Array<{ __typename: "PlaidItem" } & PlaidConnectionCardContentFragment> };
  shopifyShops: { __typename: "ShopifyShopConnection" } & {
    nodes: Array<{ __typename: "ShopifyShop" } & ShopifyConnectionCardContentFragment>;
  };
  googleAnalyticsCredentials: { __typename: "GoogleAnalyticsCredentialConnection" } & {
    nodes: Array<{ __typename: "GoogleAnalyticsCredential" } & GoogleAnalyticsConnectionCardContentFragment>;
  };
};

export type GetGoogleAnalyticsViewsQueryVariables = {
  credentialId: Scalars["ID"];
};

export type GetGoogleAnalyticsViewsQuery = { __typename: "AppQuery" } & {
  googleAnalyticsViews: { __typename: "GoogleAnalyticsViewConnection" } & {
    nodes: Array<
      { __typename: "GoogleAnalyticsView" } & Pick<
        GoogleAnalyticsView,
        "name" | "id" | "propertyName" | "propertyId" | "accountName" | "accountId" | "alreadySetup"
      >
    >;
  };
};

export type CompleteGoogleAnalyticsSetupMutationVariables = {
  credentialId: Scalars["ID"];
  viewId: Scalars["String"];
};

export type CompleteGoogleAnalyticsSetupMutation = { __typename: "AppMutation" } & {
  completeGoogleAnalyticsSetup: Maybe<
    { __typename: "CompleteGoogleAnalyticsSetupPayload" } & {
      googleAnalyticsCredential: Maybe<{ __typename: "GoogleAnalyticsCredential" } & Pick<GoogleAnalyticsCredential, "id">>;
    }
  >;
};

export type GoogleAnalyticsConnectionCardContentFragment = { __typename: "GoogleAnalyticsCredential" } & Pick<
  GoogleAnalyticsCredential,
  "id" | "viewName" | "propertyName" | "accountName"
>;

export type PlaidConnectionCardContentFragment = { __typename: "PlaidItem" } & Pick<PlaidItem, "id"> & {
    accounts: Array<{ __typename: "PlaidItemAccount" } & Pick<PlaidItemAccount, "id" | "name" | "type">>;
  };

export type ConnectPlaidMutationVariables = {
  publicToken: Scalars["String"];
};

export type ConnectPlaidMutation = { __typename: "AppMutation" } & {
  connectPlaid: Maybe<
    { __typename: "ConnectPlaidPayload" } & { plaidItem: Maybe<{ __typename: "PlaidItem" } & PlaidConnectionCardContentFragment> }
  >;
};

export type RestartConnectionSyncMutationVariables = {
  connectionId: Scalars["ID"];
};

export type RestartConnectionSyncMutation = { __typename: "AppMutation" } & {
  restartConnectionSync: Maybe<
    { __typename: "RestartConnectionSyncPayload" } & Pick<RestartConnectionSyncPayload, "errors"> & {
        connection: Maybe<{ __typename: "Connection" } & Pick<Connection, "id">>;
      }
  >;
};

export type ShopifyConnectionCardContentFragment = { __typename: "ShopifyShop" } & Pick<
  ShopifyShop,
  "id" | "name" | "shopifyDomain" | "shopId"
> & { connection: { __typename: "Connection" } & Pick<Connection, "id"> };

export type ConnectShopifyMutationVariables = {
  apiKey: Scalars["String"];
  password: Scalars["String"];
  domain: Scalars["String"];
};

export type ConnectShopifyMutation = { __typename: "AppMutation" } & {
  connectShopify: Maybe<
    { __typename: "ConnectShopifyPayload" } & Pick<ConnectShopifyPayload, "errors"> & {
        shopifyShop: Maybe<{ __typename: "ShopifyShop" } & ShopifyConnectionCardContentFragment>;
      }
  >;
};

export type InviteNewUserMutationVariables = {
  user: UserInviteAttributes;
};

export type InviteNewUserMutation = { __typename: "AppMutation" } & {
  inviteUser: Maybe<
    { __typename: "InviteUserPayload" } & Pick<InviteUserPayload, "success"> & {
        errors: Maybe<Array<{ __typename: "MutationError" } & Pick<MutationError, "fullMessage">>>;
      }
  >;
};

export type GetUsersForSettingsQueryVariables = {};

export type GetUsersForSettingsQuery = { __typename: "AppQuery" } & {
  users: { __typename: "UserConnection" } & {
    nodes: Array<{ __typename: "User" } & Pick<User, "id" | "fullName" | "email" | "pendingInvitation"> & UserCardFragment>;
  };
};

export type AttachUploadToContainerMutationVariables = {
  directUploadSignedId: Scalars["String"];
  attachmentContainerId: Scalars["ID"];
  attachmentContainerType: AttachmentContainerEnum;
};

export type AttachUploadToContainerMutation = { __typename: "AppMutation" } & {
  attachDirectUploadedFile: Maybe<
    { __typename: "AttachDirectUploadedFilePayload" } & Pick<AttachDirectUploadedFilePayload, "errors"> & {
        attachment: Maybe<{ __typename: "Attachment" } & Pick<Attachment, "id" | "filename" | "contentType" | "bytesize" | "url">>;
      }
  >;
};

export type AttachRemoteUrlToContainerMutationVariables = {
  url: Scalars["String"];
  attachmentContainerId: Scalars["ID"];
  attachmentContainerType: AttachmentContainerEnum;
};

export type AttachRemoteUrlToContainerMutation = { __typename: "AppMutation" } & {
  attachRemoteUrl: Maybe<
    { __typename: "AttachRemoteUrlPayload" } & Pick<AttachRemoteUrlPayload, "errors"> & {
        attachment: Maybe<{ __typename: "Attachment" } & Pick<Attachment, "id" | "filename" | "contentType" | "bytesize" | "url">>;
      }
  >;
};
export const UserCardFragmentDoc = gql`
  fragment UserCard on User {
    id
    email
    primaryTextIdentifier
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
export const ShopifyConnectionCardContentFragmentDoc = gql`
  fragment ShopifyConnectionCardContent on ShopifyShop {
    id
    name
    shopifyDomain
    shopId
    connection {
      id
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
    }
  }
  ${UserCardFragmentDoc}
`;
export type SiderInfoComponentProps = Omit<ReactApollo.QueryProps<SiderInfoQuery, SiderInfoQueryVariables>, "query">;

export const SiderInfoComponent = (props: SiderInfoComponentProps) => (
  <ReactApollo.Query<SiderInfoQuery, SiderInfoQueryVariables> query={SiderInfoDocument} {...props} />
);

export function useSiderInfoQuery(baseOptions?: ReactApolloHooks.QueryHookOptions<SiderInfoQueryVariables>) {
  return ReactApolloHooks.useQuery<SiderInfoQuery, SiderInfoQueryVariables>(SiderInfoDocument, baseOptions);
}
export const GetAccountForSettingsDocument = gql`
  query GetAccountForSettings {
    account: currentAccount {
      id
      name
    }
  }
`;
export type GetAccountForSettingsComponentProps = Omit<
  ReactApollo.QueryProps<GetAccountForSettingsQuery, GetAccountForSettingsQueryVariables>,
  "query"
>;

export const GetAccountForSettingsComponent = (props: GetAccountForSettingsComponentProps) => (
  <ReactApollo.Query<GetAccountForSettingsQuery, GetAccountForSettingsQueryVariables> query={GetAccountForSettingsDocument} {...props} />
);

export function useGetAccountForSettingsQuery(baseOptions?: ReactApolloHooks.QueryHookOptions<GetAccountForSettingsQueryVariables>) {
  return ReactApolloHooks.useQuery<GetAccountForSettingsQuery, GetAccountForSettingsQueryVariables>(
    GetAccountForSettingsDocument,
    baseOptions
  );
}
export const UpdateAccountSettingsDocument = gql`
  mutation UpdateAccountSettings($attributes: AccountAttributes!) {
    updateAccount(attributes: $attributes) {
      account {
        id
        name
      }
      errors {
        fullMessage
      }
    }
  }
`;
export type UpdateAccountSettingsMutationFn = ReactApollo.MutationFn<UpdateAccountSettingsMutation, UpdateAccountSettingsMutationVariables>;
export type UpdateAccountSettingsComponentProps = Omit<
  ReactApollo.MutationProps<UpdateAccountSettingsMutation, UpdateAccountSettingsMutationVariables>,
  "mutation"
>;

export const UpdateAccountSettingsComponent = (props: UpdateAccountSettingsComponentProps) => (
  <ReactApollo.Mutation<UpdateAccountSettingsMutation, UpdateAccountSettingsMutationVariables>
    mutation={UpdateAccountSettingsDocument}
    {...props}
  />
);

export function useUpdateAccountSettingsMutation(
  baseOptions?: ReactApolloHooks.MutationHookOptions<UpdateAccountSettingsMutation, UpdateAccountSettingsMutationVariables>
) {
  return ReactApolloHooks.useMutation<UpdateAccountSettingsMutation, UpdateAccountSettingsMutationVariables>(
    UpdateAccountSettingsDocument,
    baseOptions
  );
}
export const GetConnectionsIndexPageDocument = gql`
  query GetConnectionsIndexPage {
    plaidItems {
      nodes {
        ...PlaidConnectionCardContent
      }
    }
    shopifyShops {
      nodes {
        ...ShopifyConnectionCardContent
      }
    }
    googleAnalyticsCredentials {
      nodes {
        ...GoogleAnalyticsConnectionCardContent
      }
    }
  }
  ${PlaidConnectionCardContentFragmentDoc}
  ${ShopifyConnectionCardContentFragmentDoc}
  ${GoogleAnalyticsConnectionCardContentFragmentDoc}
`;
export type GetConnectionsIndexPageComponentProps = Omit<
  ReactApollo.QueryProps<GetConnectionsIndexPageQuery, GetConnectionsIndexPageQueryVariables>,
  "query"
>;

export const GetConnectionsIndexPageComponent = (props: GetConnectionsIndexPageComponentProps) => (
  <ReactApollo.Query<GetConnectionsIndexPageQuery, GetConnectionsIndexPageQueryVariables>
    query={GetConnectionsIndexPageDocument}
    {...props}
  />
);

export function useGetConnectionsIndexPageQuery(baseOptions?: ReactApolloHooks.QueryHookOptions<GetConnectionsIndexPageQueryVariables>) {
  return ReactApolloHooks.useQuery<GetConnectionsIndexPageQuery, GetConnectionsIndexPageQueryVariables>(
    GetConnectionsIndexPageDocument,
    baseOptions
  );
}
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
export type GetGoogleAnalyticsViewsComponentProps = Omit<
  ReactApollo.QueryProps<GetGoogleAnalyticsViewsQuery, GetGoogleAnalyticsViewsQueryVariables>,
  "query"
> &
  ({ variables: GetGoogleAnalyticsViewsQueryVariables; skip?: false } | { skip: true });

export const GetGoogleAnalyticsViewsComponent = (props: GetGoogleAnalyticsViewsComponentProps) => (
  <ReactApollo.Query<GetGoogleAnalyticsViewsQuery, GetGoogleAnalyticsViewsQueryVariables>
    query={GetGoogleAnalyticsViewsDocument}
    {...props}
  />
);

export function useGetGoogleAnalyticsViewsQuery(baseOptions?: ReactApolloHooks.QueryHookOptions<GetGoogleAnalyticsViewsQueryVariables>) {
  return ReactApolloHooks.useQuery<GetGoogleAnalyticsViewsQuery, GetGoogleAnalyticsViewsQueryVariables>(
    GetGoogleAnalyticsViewsDocument,
    baseOptions
  );
}
export const CompleteGoogleAnalyticsSetupDocument = gql`
  mutation CompleteGoogleAnalyticsSetup($credentialId: ID!, $viewId: String!) {
    completeGoogleAnalyticsSetup(credentialId: $credentialId, viewId: $viewId) {
      googleAnalyticsCredential {
        id
      }
    }
  }
`;
export type CompleteGoogleAnalyticsSetupMutationFn = ReactApollo.MutationFn<
  CompleteGoogleAnalyticsSetupMutation,
  CompleteGoogleAnalyticsSetupMutationVariables
>;
export type CompleteGoogleAnalyticsSetupComponentProps = Omit<
  ReactApollo.MutationProps<CompleteGoogleAnalyticsSetupMutation, CompleteGoogleAnalyticsSetupMutationVariables>,
  "mutation"
>;

export const CompleteGoogleAnalyticsSetupComponent = (props: CompleteGoogleAnalyticsSetupComponentProps) => (
  <ReactApollo.Mutation<CompleteGoogleAnalyticsSetupMutation, CompleteGoogleAnalyticsSetupMutationVariables>
    mutation={CompleteGoogleAnalyticsSetupDocument}
    {...props}
  />
);

export function useCompleteGoogleAnalyticsSetupMutation(
  baseOptions?: ReactApolloHooks.MutationHookOptions<CompleteGoogleAnalyticsSetupMutation, CompleteGoogleAnalyticsSetupMutationVariables>
) {
  return ReactApolloHooks.useMutation<CompleteGoogleAnalyticsSetupMutation, CompleteGoogleAnalyticsSetupMutationVariables>(
    CompleteGoogleAnalyticsSetupDocument,
    baseOptions
  );
}
export const ConnectPlaidDocument = gql`
  mutation ConnectPlaid($publicToken: String!) {
    connectPlaid(publicToken: $publicToken) {
      plaidItem {
        ...PlaidConnectionCardContent
      }
    }
  }
  ${PlaidConnectionCardContentFragmentDoc}
`;
export type ConnectPlaidMutationFn = ReactApollo.MutationFn<ConnectPlaidMutation, ConnectPlaidMutationVariables>;
export type ConnectPlaidComponentProps = Omit<ReactApollo.MutationProps<ConnectPlaidMutation, ConnectPlaidMutationVariables>, "mutation">;

export const ConnectPlaidComponent = (props: ConnectPlaidComponentProps) => (
  <ReactApollo.Mutation<ConnectPlaidMutation, ConnectPlaidMutationVariables> mutation={ConnectPlaidDocument} {...props} />
);

export function useConnectPlaidMutation(
  baseOptions?: ReactApolloHooks.MutationHookOptions<ConnectPlaidMutation, ConnectPlaidMutationVariables>
) {
  return ReactApolloHooks.useMutation<ConnectPlaidMutation, ConnectPlaidMutationVariables>(ConnectPlaidDocument, baseOptions);
}
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
export type RestartConnectionSyncMutationFn = ReactApollo.MutationFn<RestartConnectionSyncMutation, RestartConnectionSyncMutationVariables>;
export type RestartConnectionSyncComponentProps = Omit<
  ReactApollo.MutationProps<RestartConnectionSyncMutation, RestartConnectionSyncMutationVariables>,
  "mutation"
>;

export const RestartConnectionSyncComponent = (props: RestartConnectionSyncComponentProps) => (
  <ReactApollo.Mutation<RestartConnectionSyncMutation, RestartConnectionSyncMutationVariables>
    mutation={RestartConnectionSyncDocument}
    {...props}
  />
);

export function useRestartConnectionSyncMutation(
  baseOptions?: ReactApolloHooks.MutationHookOptions<RestartConnectionSyncMutation, RestartConnectionSyncMutationVariables>
) {
  return ReactApolloHooks.useMutation<RestartConnectionSyncMutation, RestartConnectionSyncMutationVariables>(
    RestartConnectionSyncDocument,
    baseOptions
  );
}
export const ConnectShopifyDocument = gql`
  mutation ConnectShopify($apiKey: String!, $password: String!, $domain: String!) {
    connectShopify(apiKey: $apiKey, password: $password, domain: $domain) {
      errors
      shopifyShop {
        ...ShopifyConnectionCardContent
      }
    }
  }
  ${ShopifyConnectionCardContentFragmentDoc}
`;
export type ConnectShopifyMutationFn = ReactApollo.MutationFn<ConnectShopifyMutation, ConnectShopifyMutationVariables>;
export type ConnectShopifyComponentProps = Omit<
  ReactApollo.MutationProps<ConnectShopifyMutation, ConnectShopifyMutationVariables>,
  "mutation"
>;

export const ConnectShopifyComponent = (props: ConnectShopifyComponentProps) => (
  <ReactApollo.Mutation<ConnectShopifyMutation, ConnectShopifyMutationVariables> mutation={ConnectShopifyDocument} {...props} />
);

export function useConnectShopifyMutation(
  baseOptions?: ReactApolloHooks.MutationHookOptions<ConnectShopifyMutation, ConnectShopifyMutationVariables>
) {
  return ReactApolloHooks.useMutation<ConnectShopifyMutation, ConnectShopifyMutationVariables>(ConnectShopifyDocument, baseOptions);
}
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
export type InviteNewUserMutationFn = ReactApollo.MutationFn<InviteNewUserMutation, InviteNewUserMutationVariables>;
export type InviteNewUserComponentProps = Omit<
  ReactApollo.MutationProps<InviteNewUserMutation, InviteNewUserMutationVariables>,
  "mutation"
>;

export const InviteNewUserComponent = (props: InviteNewUserComponentProps) => (
  <ReactApollo.Mutation<InviteNewUserMutation, InviteNewUserMutationVariables> mutation={InviteNewUserDocument} {...props} />
);

export function useInviteNewUserMutation(
  baseOptions?: ReactApolloHooks.MutationHookOptions<InviteNewUserMutation, InviteNewUserMutationVariables>
) {
  return ReactApolloHooks.useMutation<InviteNewUserMutation, InviteNewUserMutationVariables>(InviteNewUserDocument, baseOptions);
}
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
  ${UserCardFragmentDoc}
`;
export type GetUsersForSettingsComponentProps = Omit<
  ReactApollo.QueryProps<GetUsersForSettingsQuery, GetUsersForSettingsQueryVariables>,
  "query"
>;

export const GetUsersForSettingsComponent = (props: GetUsersForSettingsComponentProps) => (
  <ReactApollo.Query<GetUsersForSettingsQuery, GetUsersForSettingsQueryVariables> query={GetUsersForSettingsDocument} {...props} />
);

export function useGetUsersForSettingsQuery(baseOptions?: ReactApolloHooks.QueryHookOptions<GetUsersForSettingsQueryVariables>) {
  return ReactApolloHooks.useQuery<GetUsersForSettingsQuery, GetUsersForSettingsQueryVariables>(GetUsersForSettingsDocument, baseOptions);
}
export const AttachUploadToContainerDocument = gql`
  mutation AttachUploadToContainer(
    $directUploadSignedId: String!
    $attachmentContainerId: ID!
    $attachmentContainerType: AttachmentContainerEnum!
  ) {
    attachDirectUploadedFile(
      directUploadSignedId: $directUploadSignedId
      attachmentContainerId: $attachmentContainerId
      attachmentContainerType: $attachmentContainerType
    ) {
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
export type AttachUploadToContainerMutationFn = ReactApollo.MutationFn<
  AttachUploadToContainerMutation,
  AttachUploadToContainerMutationVariables
>;
export type AttachUploadToContainerComponentProps = Omit<
  ReactApollo.MutationProps<AttachUploadToContainerMutation, AttachUploadToContainerMutationVariables>,
  "mutation"
>;

export const AttachUploadToContainerComponent = (props: AttachUploadToContainerComponentProps) => (
  <ReactApollo.Mutation<AttachUploadToContainerMutation, AttachUploadToContainerMutationVariables>
    mutation={AttachUploadToContainerDocument}
    {...props}
  />
);

export function useAttachUploadToContainerMutation(
  baseOptions?: ReactApolloHooks.MutationHookOptions<AttachUploadToContainerMutation, AttachUploadToContainerMutationVariables>
) {
  return ReactApolloHooks.useMutation<AttachUploadToContainerMutation, AttachUploadToContainerMutationVariables>(
    AttachUploadToContainerDocument,
    baseOptions
  );
}
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
export type AttachRemoteUrlToContainerMutationFn = ReactApollo.MutationFn<
  AttachRemoteUrlToContainerMutation,
  AttachRemoteUrlToContainerMutationVariables
>;
export type AttachRemoteUrlToContainerComponentProps = Omit<
  ReactApollo.MutationProps<AttachRemoteUrlToContainerMutation, AttachRemoteUrlToContainerMutationVariables>,
  "mutation"
>;

export const AttachRemoteUrlToContainerComponent = (props: AttachRemoteUrlToContainerComponentProps) => (
  <ReactApollo.Mutation<AttachRemoteUrlToContainerMutation, AttachRemoteUrlToContainerMutationVariables>
    mutation={AttachRemoteUrlToContainerDocument}
    {...props}
  />
);

export function useAttachRemoteUrlToContainerMutation(
  baseOptions?: ReactApolloHooks.MutationHookOptions<AttachRemoteUrlToContainerMutation, AttachRemoteUrlToContainerMutationVariables>
) {
  return ReactApolloHooks.useMutation<AttachRemoteUrlToContainerMutation, AttachRemoteUrlToContainerMutationVariables>(
    AttachRemoteUrlToContainerDocument,
    baseOptions
  );
}
