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
  /** Untyped JSON output useful for bags of values who's keys or types can't be predicted ahead of time. */
  JSONScalar: any;
  /** Represents textual data as UTF-8 character sequences. This type is most often
   * used by GraphQL to represent free-form human-readable text.
   */
  RecurrenceRuleString: string;
  /** Represents textual data as UTF-8 character sequences. This type is most often
   * used by GraphQL to represent free-form human-readable text.
   */
  MutationClientId: any;
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
  createProcessExecution?: Maybe<CreateProcessExecutionPayload>;
  createProcessTemplate?: Maybe<CreateProcessTemplatePayload>;
  createScratchpad?: Maybe<CreateScratchpadPayload>;
  discardProcessExecution?: Maybe<DiscardProcessExecutionPayload>;
  discardProcessTemplate?: Maybe<DiscardProcessTemplatePayload>;
  discardScratchpad?: Maybe<DiscardScratchpadPayload>;
  inviteUser?: Maybe<InviteUserPayload>;
  updateAccount?: Maybe<UpdateAccountPayload>;
  updateBudget?: Maybe<UpdateBudgetPayload>;
  updateProcessExecution?: Maybe<UpdateProcessExecutionPayload>;
  updateProcessTemplate?: Maybe<UpdateProcessTemplatePayload>;
  updateScratchpad?: Maybe<UpdateScratchpadPayload>;
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

export type AppMutationCreateProcessExecutionArgs = {
  attributes?: Maybe<ProcessExecutionAttributes>;
};

export type AppMutationCreateProcessTemplateArgs = {
  attributes?: Maybe<ProcessTemplateAttributes>;
};

export type AppMutationCreateScratchpadArgs = {
  attributes?: Maybe<ScratchpadAttributes>;
};

export type AppMutationDiscardProcessExecutionArgs = {
  id: Scalars["ID"];
};

export type AppMutationDiscardProcessTemplateArgs = {
  id: Scalars["ID"];
};

export type AppMutationDiscardScratchpadArgs = {
  id: Scalars["ID"];
};

export type AppMutationInviteUserArgs = {
  user: UserInviteAttributes;
};

export type AppMutationUpdateAccountArgs = {
  attributes: AccountAttributes;
};

export type AppMutationUpdateBudgetArgs = {
  id: Scalars["ID"];
  attributes: BudgetAttributes;
};

export type AppMutationUpdateProcessExecutionArgs = {
  id: Scalars["ID"];
  attributes: ProcessExecutionAttributes;
};

export type AppMutationUpdateProcessTemplateArgs = {
  id: Scalars["ID"];
  attributes: ProcessTemplateAttributes;
};

export type AppMutationUpdateScratchpadArgs = {
  id: Scalars["ID"];
  attributes: ScratchpadAttributes;
};

export type AppQuery = {
  __typename: "AppQuery";
  /** Find a budget by ID */
  budget?: Maybe<Budget>;
  /** Fetch all budgets in the system */
  budgets: BudgetConnection;
  /** Get the details of the current account */
  currentAccount: Account;
  /** Get the details of the currently logged in user */
  currentUser: User;
  /** Get the default budget premade for all accounts */
  defaultBudget: Budget;
  /** Find a process execution by ID */
  processExecution?: Maybe<ProcessExecution>;
  /** Get all the process executions */
  processExecutions: ProcessExecutionConnection;
  /** Find a process template by ID */
  processTemplate?: Maybe<ProcessTemplate>;
  /** Get all the process templates */
  processTemplates: ProcessTemplateConnection;
  /** Find a scratchpad by ID */
  scratchpad?: Maybe<Scratchpad>;
  /** Get all the scratchpads for the current user */
  scratchpads: ScratchpadConnection;
  /** Get all the active users in the current account */
  users: UserConnection;
};

export type AppQueryBudgetArgs = {
  id: Scalars["ID"];
};

export type AppQueryBudgetsArgs = {
  after?: Maybe<Scalars["String"]>;
  before?: Maybe<Scalars["String"]>;
  first?: Maybe<Scalars["Int"]>;
  last?: Maybe<Scalars["Int"]>;
};

export type AppQueryProcessExecutionArgs = {
  id: Scalars["ID"];
};

export type AppQueryProcessExecutionsArgs = {
  after?: Maybe<Scalars["String"]>;
  before?: Maybe<Scalars["String"]>;
  first?: Maybe<Scalars["Int"]>;
  last?: Maybe<Scalars["Int"]>;
};

export type AppQueryProcessTemplateArgs = {
  id: Scalars["ID"];
};

export type AppQueryProcessTemplatesArgs = {
  after?: Maybe<Scalars["String"]>;
  before?: Maybe<Scalars["String"]>;
  first?: Maybe<Scalars["Int"]>;
  last?: Maybe<Scalars["Int"]>;
};

export type AppQueryScratchpadArgs = {
  id: Scalars["ID"];
};

export type AppQueryScratchpadsArgs = {
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
  /** A scratchpad */
  Scratchpad = "SCRATCHPAD",
  /** A process execution */
  ProcessExecution = "PROCESS_EXECUTION",
  /** A process template */
  ProcessTemplate = "PROCESS_TEMPLATE"
}

/** Autogenerated return type of AttachRemoteUrl */
export type AttachRemoteUrlPayload = {
  __typename: "AttachRemoteUrlPayload";
  attachment?: Maybe<Attachment>;
  errors?: Maybe<Array<Scalars["String"]>>;
};

export type Budget = {
  __typename: "Budget";
  budgetLines: Array<BudgetLine>;
  createdAt: Scalars["ISO8601DateTime"];
  creator: User;
  discardedAt: Scalars["ISO8601DateTime"];
  id: Scalars["ID"];
  name: Scalars["String"];
  problemSpots: Array<BudgetProblemSpot>;
  sections: Array<Scalars["String"]>;
  updatedAt: Scalars["ISO8601DateTime"];
};

/** Attributes for creating or updating a budget */
export type BudgetAttributes = {
  /** An opaque identifier that will appear on objects created/updated because of
   * this attributes hash, or on errors from it being invalid.
   */
  mutationClientId?: Maybe<Scalars["MutationClientId"]>;
  /** Name to set on the budget */
  name?: Maybe<Scalars["String"]>;
  budgetLines: Array<BudgetLineAttributes>;
};

/** The connection type for Budget. */
export type BudgetConnection = {
  __typename: "BudgetConnection";
  /** A list of edges. */
  edges: Array<BudgetEdge>;
  /** A list of nodes. */
  nodes: Array<Budget>;
  /** Information to aid in pagination. */
  pageInfo: PageInfo;
};

/** An edge in a connection. */
export type BudgetEdge = {
  __typename: "BudgetEdge";
  /** A cursor for use in pagination. */
  cursor: Scalars["String"];
  /** The item at the end of the edge. */
  node?: Maybe<Budget>;
};

export type BudgetLine = {
  __typename: "BudgetLine";
  amount: Money;
  budget: Budget;
  createdAt: Scalars["ISO8601DateTime"];
  creator: User;
  description: Scalars["String"];
  discardedAt: Scalars["ISO8601DateTime"];
  id: Scalars["ID"];
  section: Scalars["String"];
  sortOrder: Scalars["Int"];
  updatedAt: Scalars["ISO8601DateTime"];
  value: BudgetLineValue;
};

export type BudgetLineAttributes = {
  /** An opaque identifier that will appear on objects created/updated because of
   * this attributes hash, or on errors from it being invalid.
   */
  mutationClientId?: Maybe<Scalars["MutationClientId"]>;
  id: Scalars["ID"];
  description: Scalars["String"];
  section: Scalars["String"];
  sortOrder: Scalars["Int"];
  value: BudgetLineValueAttributes;
};

export type BudgetLineFixedValue = {
  __typename: "BudgetLineFixedValue";
  amountScenarios: Scalars["JSONScalar"];
  occursAt: Scalars["ISO8601DateTime"];
  recurrenceRules?: Maybe<Array<Scalars["RecurrenceRuleString"]>>;
  type: Scalars["String"];
};

export type BudgetLineSeriesCell = {
  __typename: "BudgetLineSeriesCell";
  amountScenarios: Scalars["JSONScalar"];
  dateTime: Scalars["ISO8601DateTime"];
};

export type BudgetLineSeriesCellAttributes = {
  /** An opaque identifier that will appear on objects created/updated because of
   * this attributes hash, or on errors from it being invalid.
   */
  mutationClientId?: Maybe<Scalars["MutationClientId"]>;
  dateTime?: Maybe<Scalars["ISO8601DateTime"]>;
  amountScenarios?: Maybe<Scalars["JSONScalar"]>;
};

export type BudgetLineSeriesValue = {
  __typename: "BudgetLineSeriesValue";
  cells: Array<BudgetLineSeriesCell>;
  type: Scalars["String"];
};

/** How the value over time of a budget line is expressed */
export type BudgetLineValue = BudgetLineFixedValue | BudgetLineSeriesValue;

export type BudgetLineValueAttributes = {
  /** An opaque identifier that will appear on objects created/updated because of
   * this attributes hash, or on errors from it being invalid.
   */
  mutationClientId?: Maybe<Scalars["MutationClientId"]>;
  type: Scalars["String"];
  occursAt?: Maybe<Scalars["ISO8601DateTime"]>;
  recurrenceRules?: Maybe<Array<Scalars["RecurrenceRuleString"]>>;
  amountScenarios?: Maybe<Scalars["JSONScalar"]>;
  cells?: Maybe<Array<BudgetLineSeriesCellAttributes>>;
};

export type BudgetProblemSpot = {
  __typename: "BudgetProblemSpot";
  endDate: Scalars["ISO8601DateTime"];
  minCashOnHand: Money;
  scenario: Scalars["String"];
  spotNumber: Scalars["Int"];
  startDate: Scalars["ISO8601DateTime"];
};

/** Autogenerated return type of CreateProcessExecution */
export type CreateProcessExecutionPayload = {
  __typename: "CreateProcessExecutionPayload";
  errors?: Maybe<Array<MutationError>>;
  processExecution?: Maybe<ProcessExecution>;
};

/** Autogenerated return type of CreateProcessTemplate */
export type CreateProcessTemplatePayload = {
  __typename: "CreateProcessTemplatePayload";
  errors?: Maybe<Array<MutationError>>;
  processTemplate?: Maybe<ProcessTemplate>;
};

/** Autogenerated return type of CreateScratchpad */
export type CreateScratchpadPayload = {
  __typename: "CreateScratchpadPayload";
  errors?: Maybe<Array<MutationError>>;
  scratchpad?: Maybe<Scratchpad>;
};

export type Currency = {
  __typename: "Currency";
  decimalMark: Scalars["String"];
  isoCode: Scalars["String"];
  name: Scalars["String"];
  symbol: Scalars["String"];
  symbolFirst: Scalars["Boolean"];
  thousandsSeparator: Scalars["String"];
};

/** Autogenerated return type of DiscardProcessExecution */
export type DiscardProcessExecutionPayload = {
  __typename: "DiscardProcessExecutionPayload";
  errors?: Maybe<Array<MutationError>>;
  processExecution?: Maybe<ProcessExecution>;
};

/** Autogenerated return type of DiscardProcessTemplate */
export type DiscardProcessTemplatePayload = {
  __typename: "DiscardProcessTemplatePayload";
  errors?: Maybe<Array<MutationError>>;
  processTemplate?: Maybe<ProcessTemplate>;
};

/** Autogenerated return type of DiscardScratchpad */
export type DiscardScratchpadPayload = {
  __typename: "DiscardScratchpadPayload";
  errors?: Maybe<Array<MutationError>>;
  scratchpad?: Maybe<Scratchpad>;
};

/** Autogenerated return type of InviteUser */
export type InviteUserPayload = {
  __typename: "InviteUserPayload";
  errors?: Maybe<Array<MutationError>>;
  success: Scalars["Boolean"];
};

export type Money = {
  __typename: "Money";
  currency: Currency;
  formatted: Scalars["String"];
  fractional: Scalars["Int"];
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

export type ProcessExecution = {
  __typename: "ProcessExecution";
  closedTodoCount: Scalars["Int"];
  closestFutureDeadline?: Maybe<Scalars["ISO8601DateTime"]>;
  createdAt: Scalars["ISO8601DateTime"];
  creator: User;
  discardedAt: Scalars["ISO8601DateTime"];
  document: Scalars["JSONScalar"];
  id: Scalars["ID"];
  involvedUsers: Array<User>;
  name: Scalars["String"];
  openTodoCount: Scalars["Int"];
  processTemplate?: Maybe<ProcessTemplate>;
  startedAt?: Maybe<Scalars["ISO8601DateTime"]>;
  totalTodoCount: Scalars["Int"];
  updatedAt: Scalars["ISO8601DateTime"];
};

/** Attributes for creating or updating a process execution */
export type ProcessExecutionAttributes = {
  /** An opaque identifier that will appear on objects created/updated because of
   * this attributes hash, or on errors from it being invalid.
   */
  mutationClientId?: Maybe<Scalars["MutationClientId"]>;
  /** Name to set */
  name?: Maybe<Scalars["String"]>;
  /** Opaque JSON document powering the document editor for the process template */
  document?: Maybe<Scalars["JSONScalar"]>;
  /** ID of the process template that spawned this execution */
  processTemplateId?: Maybe<Scalars["ID"]>;
  startedAt?: Maybe<Scalars["ISO8601DateTime"]>;
  startNow?: Maybe<Scalars["Boolean"]>;
};

/** The connection type for ProcessExecution. */
export type ProcessExecutionConnection = {
  __typename: "ProcessExecutionConnection";
  /** A list of edges. */
  edges: Array<ProcessExecutionEdge>;
  /** A list of nodes. */
  nodes: Array<ProcessExecution>;
  /** Information to aid in pagination. */
  pageInfo: PageInfo;
};

/** An edge in a connection. */
export type ProcessExecutionEdge = {
  __typename: "ProcessExecutionEdge";
  /** A cursor for use in pagination. */
  cursor: Scalars["String"];
  /** The item at the end of the edge. */
  node?: Maybe<ProcessExecution>;
};

export type ProcessTemplate = {
  __typename: "ProcessTemplate";
  createdAt: Scalars["ISO8601DateTime"];
  creator: User;
  discardedAt: Scalars["ISO8601DateTime"];
  document: Scalars["JSONScalar"];
  executionCount: Scalars["Int"];
  id: Scalars["ID"];
  lastExecution?: Maybe<ProcessExecution>;
  name: Scalars["String"];
  updatedAt: Scalars["ISO8601DateTime"];
};

/** Attributes for creating or updating a process template */
export type ProcessTemplateAttributes = {
  /** An opaque identifier that will appear on objects created/updated because of
   * this attributes hash, or on errors from it being invalid.
   */
  mutationClientId?: Maybe<Scalars["MutationClientId"]>;
  /** Name to set */
  name?: Maybe<Scalars["String"]>;
  /** Opaque JSON document powering the document editor for the process template */
  document?: Maybe<Scalars["JSONScalar"]>;
};

/** The connection type for ProcessTemplate. */
export type ProcessTemplateConnection = {
  __typename: "ProcessTemplateConnection";
  /** A list of edges. */
  edges: Array<ProcessTemplateEdge>;
  /** A list of nodes. */
  nodes: Array<ProcessTemplate>;
  /** Information to aid in pagination. */
  pageInfo: PageInfo;
};

/** An edge in a connection. */
export type ProcessTemplateEdge = {
  __typename: "ProcessTemplateEdge";
  /** A cursor for use in pagination. */
  cursor: Scalars["String"];
  /** The item at the end of the edge. */
  node?: Maybe<ProcessTemplate>;
};

export type Scratchpad = {
  __typename: "Scratchpad";
  accessMode: ScratchpadAccessModeEnum;
  closedTodoCount: Scalars["Int"];
  closestFutureDeadline?: Maybe<Scalars["ISO8601DateTime"]>;
  createdAt: Scalars["ISO8601DateTime"];
  creator: User;
  discardedAt: Scalars["ISO8601DateTime"];
  document: Scalars["JSONScalar"];
  id: Scalars["ID"];
  name: Scalars["String"];
  openTodoCount: Scalars["Int"];
  totalTodoCount: Scalars["Int"];
  updatedAt: Scalars["ISO8601DateTime"];
};

export const enum ScratchpadAccessModeEnum {
  /** All members of the account can view and edit this scratchpad */
  Public = "PUBLIC",
  /** Only the creator of the scratchpad can view and edit it with no exceptions. */
  Private = "PRIVATE"
}

/** Attributes for creating or updating a scratchpad */
export type ScratchpadAttributes = {
  /** An opaque identifier that will appear on objects created/updated because of
   * this attributes hash, or on errors from it being invalid.
   */
  mutationClientId?: Maybe<Scalars["MutationClientId"]>;
  /** Opaque JSON document powering the document editor for the scratchpad */
  document?: Maybe<Scalars["JSONScalar"]>;
  accessMode?: Maybe<ScratchpadAccessModeEnum>;
};

/** The connection type for Scratchpad. */
export type ScratchpadConnection = {
  __typename: "ScratchpadConnection";
  /** A list of edges. */
  edges: Array<ScratchpadEdge>;
  /** A list of nodes. */
  nodes: Array<Scratchpad>;
  /** Information to aid in pagination. */
  pageInfo: PageInfo;
};

/** An edge in a connection. */
export type ScratchpadEdge = {
  __typename: "ScratchpadEdge";
  /** A cursor for use in pagination. */
  cursor: Scalars["String"];
  /** The item at the end of the edge. */
  node?: Maybe<Scratchpad>;
};

export type TodoFeedItem = {
  __typename: "TodoFeedItem";
  createdAt: Scalars["ISO8601DateTime"];
  creator: User;
  id: Scalars["ID"];
  todoSource: TodoFeedItemSourceUnion;
  updatedAt: Scalars["ISO8601DateTime"];
};

/** The connection type for TodoFeedItem. */
export type TodoFeedItemConnection = {
  __typename: "TodoFeedItemConnection";
  /** A list of edges. */
  edges: Array<TodoFeedItemEdge>;
  /** A list of nodes. */
  nodes: Array<TodoFeedItem>;
  /** Information to aid in pagination. */
  pageInfo: PageInfo;
};

/** An edge in a connection. */
export type TodoFeedItemEdge = {
  __typename: "TodoFeedItemEdge";
  /** A cursor for use in pagination. */
  cursor: Scalars["String"];
  /** The item at the end of the edge. */
  node?: Maybe<TodoFeedItem>;
};

/** Objects which create entries in the todo feed */
export type TodoFeedItemSourceUnion = ProcessExecution | Scratchpad;

/** Autogenerated return type of UpdateAccount */
export type UpdateAccountPayload = {
  __typename: "UpdateAccountPayload";
  account?: Maybe<Account>;
  errors?: Maybe<Array<MutationError>>;
};

/** Autogenerated return type of UpdateBudget */
export type UpdateBudgetPayload = {
  __typename: "UpdateBudgetPayload";
  budget?: Maybe<Budget>;
  errors?: Maybe<Array<MutationError>>;
};

/** Autogenerated return type of UpdateProcessExecution */
export type UpdateProcessExecutionPayload = {
  __typename: "UpdateProcessExecutionPayload";
  errors?: Maybe<Array<MutationError>>;
  processExecution?: Maybe<ProcessExecution>;
};

/** Autogenerated return type of UpdateProcessTemplate */
export type UpdateProcessTemplatePayload = {
  __typename: "UpdateProcessTemplatePayload";
  errors?: Maybe<Array<MutationError>>;
  processTemplate?: Maybe<ProcessTemplate>;
};

/** Autogenerated return type of UpdateScratchpad */
export type UpdateScratchpadPayload = {
  __typename: "UpdateScratchpadPayload";
  errors?: Maybe<Array<MutationError>>;
  scratchpad?: Maybe<Scratchpad>;
};

export type User = {
  __typename: "User";
  accounts: Array<Account>;
  authAreaUrl: Scalars["String"];
  createdAt: Scalars["ISO8601DateTime"];
  email: Scalars["String"];
  fullName?: Maybe<Scalars["String"]>;
  id: Scalars["ID"];
  involvedProcessExecutions: ProcessExecutionConnection;
  pendingInvitation: Scalars["Boolean"];
  primaryTextIdentifier: Scalars["String"];
  scratchpads: ScratchpadConnection;
  secondaryTextIdentifier?: Maybe<Scalars["String"]>;
  todoFeedItems: TodoFeedItemConnection;
  updatedAt: Scalars["ISO8601DateTime"];
};

export type UserInvolvedProcessExecutionsArgs = {
  after?: Maybe<Scalars["String"]>;
  before?: Maybe<Scalars["String"]>;
  first?: Maybe<Scalars["Int"]>;
  last?: Maybe<Scalars["Int"]>;
};

export type UserScratchpadsArgs = {
  after?: Maybe<Scalars["String"]>;
  before?: Maybe<Scalars["String"]>;
  first?: Maybe<Scalars["Int"]>;
  last?: Maybe<Scalars["Int"]>;
};

export type UserTodoFeedItemsArgs = {
  after?: Maybe<Scalars["String"]>;
  before?: Maybe<Scalars["String"]>;
  first?: Maybe<Scalars["Int"]>;
  last?: Maybe<Scalars["Int"]>;
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
export type GetBudgetForReportsQueryVariables = {};

export type GetBudgetForReportsQuery = { __typename: "AppQuery" } & {
  budget: { __typename: "Budget" } & Pick<Budget, "id" | "name" | "sections">;
};

export type BudgetForEditFragment = { __typename: "Budget" } & Pick<Budget, "id" | "name"> & {
    budgetLines: Array<
      { __typename: "BudgetLine" } & Pick<BudgetLine, "id" | "description" | "section" | "sortOrder"> & {
          value:
            | ({ __typename: "BudgetLineFixedValue" } & Pick<
                BudgetLineFixedValue,
                "type" | "occursAt" | "recurrenceRules" | "amountScenarios"
              >)
            | ({ __typename: "BudgetLineSeriesValue" } & Pick<BudgetLineSeriesValue, "type"> & {
                  cells: Array<{ __typename: "BudgetLineSeriesCell" } & Pick<BudgetLineSeriesCell, "dateTime" | "amountScenarios">>;
                });
        }
    >;
  };

export type GetBudgetForEditQueryVariables = {};

export type GetBudgetForEditQuery = { __typename: "AppQuery" } & { budget: { __typename: "Budget" } & BudgetForEditFragment };

export type UpdateBudgetMutationVariables = {
  id: Scalars["ID"];
  attributes: BudgetAttributes;
};

export type UpdateBudgetMutation = { __typename: "AppMutation" } & {
  updateBudget: Maybe<
    { __typename: "UpdateBudgetPayload" } & {
      budget: Maybe<{ __typename: "Budget" } & BudgetForEditFragment>;
      errors: Maybe<Array<{ __typename: "MutationError" } & Pick<MutationError, "field" | "fullMessage">>>;
    }
  >;
};

export type GetBudgetProblemSpotsQueryVariables = {
  id: Scalars["ID"];
};

export type GetBudgetProblemSpotsQuery = { __typename: "AppQuery" } & {
  budget: Maybe<
    { __typename: "Budget" } & Pick<Budget, "id"> & {
        problemSpots: Array<
          { __typename: "BudgetProblemSpot" } & Pick<BudgetProblemSpot, "startDate" | "endDate"> & {
              minCashOnHand: { __typename: "Money" } & Pick<Money, "formatted">;
            }
        >;
      }
  >;
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

export type CondensedProcessExecutionFormFragment = { __typename: "ProcessExecution" } & Pick<ProcessExecution, "id" | "document" | "name">;

export type UpdateProcessExecutionTodosPageMutationVariables = {
  id: Scalars["ID"];
  attributes: ProcessExecutionAttributes;
};

export type UpdateProcessExecutionTodosPageMutation = { __typename: "AppMutation" } & {
  updateProcessExecution: Maybe<
    { __typename: "UpdateProcessExecutionPayload" } & {
      processExecution: Maybe<{ __typename: "ProcessExecution" } & Pick<ProcessExecution, "id" | "updatedAt">>;
      errors: Maybe<Array<{ __typename: "MutationError" } & Pick<MutationError, "fullMessage">>>;
    }
  >;
};

export type CreateNewProcessTemplateMutationVariables = {};

export type CreateNewProcessTemplateMutation = { __typename: "AppMutation" } & {
  createProcessTemplate: Maybe<
    { __typename: "CreateProcessTemplatePayload" } & {
      processTemplate: Maybe<{ __typename: "ProcessTemplate" } & Pick<ProcessTemplate, "id">>;
      errors: Maybe<Array<{ __typename: "MutationError" } & Pick<MutationError, "fullMessage">>>;
    }
  >;
};

export type GetProcessTemplateForEditQueryVariables = {
  id: Scalars["ID"];
};

export type GetProcessTemplateForEditQuery = { __typename: "AppQuery" } & {
  processTemplate: Maybe<{ __typename: "ProcessTemplate" } & Pick<ProcessTemplate, "id" | "name" | "document" | "createdAt" | "updatedAt">>;
} & ContextForTodoEditorFragment;

export type UpdateProcessTemplateMutationVariables = {
  id: Scalars["ID"];
  attributes: ProcessTemplateAttributes;
};

export type UpdateProcessTemplateMutation = { __typename: "AppMutation" } & {
  updateProcessTemplate: Maybe<
    { __typename: "UpdateProcessTemplatePayload" } & {
      processTemplate: Maybe<{ __typename: "ProcessTemplate" } & Pick<ProcessTemplate, "id" | "updatedAt">>;
      errors: Maybe<Array<{ __typename: "MutationError" } & Pick<MutationError, "fullMessage">>>;
    }
  >;
};

export type GetProcessExecutionForEditQueryVariables = {
  id: Scalars["ID"];
};

export type GetProcessExecutionForEditQuery = { __typename: "AppQuery" } & {
  processExecution: Maybe<
    { __typename: "ProcessExecution" } & Pick<ProcessExecution, "id" | "name" | "startedAt" | "document" | "createdAt" | "updatedAt"> & {
        processTemplate: Maybe<{ __typename: "ProcessTemplate" } & Pick<ProcessTemplate, "id" | "name">>;
      }
  >;
} & ContextForTodoEditorFragment;

export type UpdateProcessExecutionMutationVariables = {
  id: Scalars["ID"];
  attributes: ProcessExecutionAttributes;
};

export type UpdateProcessExecutionMutation = { __typename: "AppMutation" } & {
  updateProcessExecution: Maybe<
    { __typename: "UpdateProcessExecutionPayload" } & {
      processExecution: Maybe<{ __typename: "ProcessExecution" } & Pick<ProcessExecution, "id" | "updatedAt">>;
      errors: Maybe<Array<{ __typename: "MutationError" } & Pick<MutationError, "fullMessage">>>;
    }
  >;
};

export type GetAllProcessTemplatesQueryVariables = {};

export type GetAllProcessTemplatesQuery = { __typename: "AppQuery" } & {
  processTemplates: { __typename: "ProcessTemplateConnection" } & {
    nodes: Array<
      { __typename: "ProcessTemplate" } & Pick<ProcessTemplate, "id" | "name"> & { key: ProcessTemplate["id"] } & {
          creator: { __typename: "User" } & UserCardFragment;
          lastExecution: Maybe<{ __typename: "ProcessExecution" } & Pick<ProcessExecution, "id" | "startedAt" | "createdAt">>;
        }
    >;
  };
};

export type DiscardProcessTemplateMutationVariables = {
  id: Scalars["ID"];
};

export type DiscardProcessTemplateMutation = { __typename: "AppMutation" } & {
  discardProcessTemplate: Maybe<
    { __typename: "DiscardProcessTemplatePayload" } & {
      processTemplate: Maybe<{ __typename: "ProcessTemplate" } & Pick<ProcessTemplate, "id" | "discardedAt">>;
      errors: Maybe<Array<{ __typename: "MutationError" } & Pick<MutationError, "fullMessage">>>;
    }
  >;
};

export type GetAllProcessExecutionsQueryVariables = {};

export type GetAllProcessExecutionsQuery = { __typename: "AppQuery" } & {
  processExecutions: { __typename: "ProcessExecutionConnection" } & {
    nodes: Array<
      { __typename: "ProcessExecution" } & Pick<
        ProcessExecution,
        "id" | "name" | "startedAt" | "openTodoCount" | "closedTodoCount" | "totalTodoCount" | "closestFutureDeadline"
      > & { key: ProcessExecution["id"] } & { involvedUsers: Array<{ __typename: "User" } & UserCardFragment> }
    >;
  };
};

export type CreateNewProcessExecutionMutationVariables = {};

export type CreateNewProcessExecutionMutation = { __typename: "AppMutation" } & {
  createProcessExecution: Maybe<
    { __typename: "CreateProcessExecutionPayload" } & {
      processExecution: Maybe<{ __typename: "ProcessExecution" } & Pick<ProcessExecution, "id">>;
      errors: Maybe<Array<{ __typename: "MutationError" } & Pick<MutationError, "fullMessage">>>;
    }
  >;
};

export type DiscardProcessExecutionMutationVariables = {
  id: Scalars["ID"];
};

export type DiscardProcessExecutionMutation = { __typename: "AppMutation" } & {
  discardProcessExecution: Maybe<
    { __typename: "DiscardProcessExecutionPayload" } & {
      processExecution: Maybe<{ __typename: "ProcessExecution" } & Pick<ProcessExecution, "id" | "discardedAt">>;
      errors: Maybe<Array<{ __typename: "MutationError" } & Pick<MutationError, "fullMessage">>>;
    }
  >;
};

export type ScratchpadFormFragment = { __typename: "Scratchpad" } & Pick<Scratchpad, "id" | "document" | "accessMode">;

export type UpdateScratchpadFromFormMutationVariables = {
  id: Scalars["ID"];
  attributes: ScratchpadAttributes;
};

export type UpdateScratchpadFromFormMutation = { __typename: "AppMutation" } & {
  updateScratchpad: Maybe<
    { __typename: "UpdateScratchpadPayload" } & {
      scratchpad: Maybe<{ __typename: "Scratchpad" } & Pick<Scratchpad, "id" | "name" | "updatedAt">>;
      errors: Maybe<Array<{ __typename: "MutationError" } & Pick<MutationError, "fullMessage">>>;
    }
  >;
};

export type GetProcessTemplateForStartQueryVariables = {
  id: Scalars["ID"];
};

export type GetProcessTemplateForStartQuery = { __typename: "AppQuery" } & {
  processTemplate: Maybe<
    { __typename: "ProcessTemplate" } & Pick<ProcessTemplate, "id" | "name" | "document" | "createdAt" | "updatedAt" | "executionCount">
  >;
} & ContextForTodoEditorFragment;

export type StartProcessExecutionMutationVariables = {
  attributes: ProcessExecutionAttributes;
};

export type StartProcessExecutionMutation = { __typename: "AppMutation" } & {
  createProcessExecution: Maybe<
    { __typename: "CreateProcessExecutionPayload" } & {
      processExecution: Maybe<{ __typename: "ProcessExecution" } & Pick<ProcessExecution, "id" | "updatedAt">>;
      errors: Maybe<Array<{ __typename: "MutationError" } & Pick<MutationError, "fullMessage">>>;
    }
  >;
};

export type GetScratchpadForSharingQueryVariables = {
  id: Scalars["ID"];
};

export type GetScratchpadForSharingQuery = { __typename: "AppQuery" } & {
  scratchpad: Maybe<{ __typename: "Scratchpad" } & Pick<Scratchpad, "id" | "accessMode">>;
};

export type SetScratchpadSharingMutationVariables = {
  id: Scalars["ID"];
  attributes: ScratchpadAttributes;
};

export type SetScratchpadSharingMutation = { __typename: "AppMutation" } & {
  updateScratchpad: Maybe<
    { __typename: "UpdateScratchpadPayload" } & {
      scratchpad: Maybe<{ __typename: "Scratchpad" } & Pick<Scratchpad, "id" | "accessMode">>;
      errors: Maybe<Array<{ __typename: "MutationError" } & Pick<MutationError, "fullMessage">>>;
    }
  >;
};

export type ContextForTodoEditorFragment = { __typename: "AppQuery" } & {
  users: { __typename: "UserConnection" } & { nodes: Array<{ __typename: "User" } & UserCardFragment> };
  currentUser: { __typename: "User" } & Pick<User, "id">;
};

export type ToolbarDiscardScratchpadMutationVariables = {
  id: Scalars["ID"];
};

export type ToolbarDiscardScratchpadMutation = { __typename: "AppMutation" } & {
  discardScratchpad: Maybe<
    { __typename: "DiscardScratchpadPayload" } & {
      scratchpad: Maybe<{ __typename: "Scratchpad" } & Pick<Scratchpad, "id" | "discardedAt">>;
      errors: Maybe<Array<{ __typename: "MutationError" } & Pick<MutationError, "fullMessage">>>;
    }
  >;
};

export type GetMyTodosQueryVariables = {
  after?: Maybe<Scalars["String"]>;
};

export type GetMyTodosQuery = { __typename: "AppQuery" } & {
  currentUser: { __typename: "User" } & Pick<User, "id"> & {
      todoFeedItems: { __typename: "TodoFeedItemConnection" } & {
        pageInfo: { __typename: "PageInfo" } & Pick<PageInfo, "endCursor" | "hasNextPage">;
        edges: Array<
          { __typename: "TodoFeedItemEdge" } & {
            node: Maybe<
              { __typename: "TodoFeedItem" } & Pick<TodoFeedItem, "id" | "updatedAt"> & {
                  todoSource:
                    | ({ __typename: "ProcessExecution" } & Pick<ProcessExecution, "id" | "name"> & {
                          involvedUsers: Array<{ __typename: "User" } & UserCardFragment>;
                        })
                    | ({ __typename: "Scratchpad" } & Pick<Scratchpad, "id" | "name">);
                }
            >;
          }
        >;
      };
    };
} & ContextForTodoEditorFragment;

export type GetProcessExecutionForTodosQueryVariables = {
  id: Scalars["ID"];
};

export type GetProcessExecutionForTodosQuery = { __typename: "AppQuery" } & {
  processExecution: Maybe<{ __typename: "ProcessExecution" } & Pick<ProcessExecution, "name"> & CondensedProcessExecutionFormFragment>;
};

export type GetScratchpadForTodosQueryVariables = {
  id: Scalars["ID"];
};

export type GetScratchpadForTodosQuery = { __typename: "AppQuery" } & {
  scratchpad: Maybe<{ __typename: "Scratchpad" } & Pick<Scratchpad, "id"> & ScratchpadFormFragment>;
};

export type CreateNewScratchpadMutationVariables = {};

export type CreateNewScratchpadMutation = { __typename: "AppMutation" } & {
  createScratchpad: Maybe<
    { __typename: "CreateScratchpadPayload" } & {
      scratchpad: Maybe<{ __typename: "Scratchpad" } & Pick<Scratchpad, "id"> & ScratchpadFormFragment>;
      errors: Maybe<Array<{ __typename: "MutationError" } & Pick<MutationError, "fullMessage">>>;
    }
  >;
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
export const BudgetForEditFragmentDoc = gql`
  fragment BudgetForEdit on Budget {
    id
    name
    budgetLines {
      id
      description
      section
      sortOrder
      value {
        __typename
        ... on BudgetLineFixedValue {
          type
          occursAt
          recurrenceRules
          amountScenarios
        }
        ... on BudgetLineSeriesValue {
          type
          cells {
            dateTime
            amountScenarios
          }
        }
      }
    }
  }
`;
export const CondensedProcessExecutionFormFragmentDoc = gql`
  fragment CondensedProcessExecutionForm on ProcessExecution {
    id
    document
    name
  }
`;
export const ScratchpadFormFragmentDoc = gql`
  fragment ScratchpadForm on Scratchpad {
    id
    document
    accessMode
  }
`;
export const UserCardFragmentDoc = gql`
  fragment UserCard on User {
    id
    email
    primaryTextIdentifier
  }
`;
export const ContextForTodoEditorFragmentDoc = gql`
  fragment ContextForTodoEditor on AppQuery {
    users {
      nodes {
        ...UserCard
      }
    }
    currentUser {
      id
    }
  }
  ${UserCardFragmentDoc}
`;
export const GetBudgetForReportsDocument = gql`
  query GetBudgetForReports {
    budget: defaultBudget {
      id
      name
      sections
    }
  }
`;
export type GetBudgetForReportsComponentProps = Omit<
  ReactApollo.QueryProps<GetBudgetForReportsQuery, GetBudgetForReportsQueryVariables>,
  "query"
>;

export const GetBudgetForReportsComponent = (props: GetBudgetForReportsComponentProps) => (
  <ReactApollo.Query<GetBudgetForReportsQuery, GetBudgetForReportsQueryVariables> query={GetBudgetForReportsDocument} {...props} />
);

export function useGetBudgetForReportsQuery(baseOptions?: ReactApolloHooks.QueryHookOptions<GetBudgetForReportsQueryVariables>) {
  return ReactApolloHooks.useQuery<GetBudgetForReportsQuery, GetBudgetForReportsQueryVariables>(GetBudgetForReportsDocument, baseOptions);
}
export const GetBudgetForEditDocument = gql`
  query GetBudgetForEdit {
    budget: defaultBudget {
      ...BudgetForEdit
    }
  }
  ${BudgetForEditFragmentDoc}
`;
export type GetBudgetForEditComponentProps = Omit<ReactApollo.QueryProps<GetBudgetForEditQuery, GetBudgetForEditQueryVariables>, "query">;

export const GetBudgetForEditComponent = (props: GetBudgetForEditComponentProps) => (
  <ReactApollo.Query<GetBudgetForEditQuery, GetBudgetForEditQueryVariables> query={GetBudgetForEditDocument} {...props} />
);

export function useGetBudgetForEditQuery(baseOptions?: ReactApolloHooks.QueryHookOptions<GetBudgetForEditQueryVariables>) {
  return ReactApolloHooks.useQuery<GetBudgetForEditQuery, GetBudgetForEditQueryVariables>(GetBudgetForEditDocument, baseOptions);
}
export const UpdateBudgetDocument = gql`
  mutation UpdateBudget($id: ID!, $attributes: BudgetAttributes!) {
    updateBudget(id: $id, attributes: $attributes) {
      budget {
        ...BudgetForEdit
      }
      errors {
        field
        fullMessage
      }
    }
  }
  ${BudgetForEditFragmentDoc}
`;
export type UpdateBudgetMutationFn = ReactApollo.MutationFn<UpdateBudgetMutation, UpdateBudgetMutationVariables>;
export type UpdateBudgetComponentProps = Omit<ReactApollo.MutationProps<UpdateBudgetMutation, UpdateBudgetMutationVariables>, "mutation">;

export const UpdateBudgetComponent = (props: UpdateBudgetComponentProps) => (
  <ReactApollo.Mutation<UpdateBudgetMutation, UpdateBudgetMutationVariables> mutation={UpdateBudgetDocument} {...props} />
);

export function useUpdateBudgetMutation(
  baseOptions?: ReactApolloHooks.MutationHookOptions<UpdateBudgetMutation, UpdateBudgetMutationVariables>
) {
  return ReactApolloHooks.useMutation<UpdateBudgetMutation, UpdateBudgetMutationVariables>(UpdateBudgetDocument, baseOptions);
}
export const GetBudgetProblemSpotsDocument = gql`
  query GetBudgetProblemSpots($id: ID!) {
    budget(id: $id) {
      id
      problemSpots {
        startDate
        endDate
        minCashOnHand {
          formatted
        }
      }
    }
  }
`;
export type GetBudgetProblemSpotsComponentProps = Omit<
  ReactApollo.QueryProps<GetBudgetProblemSpotsQuery, GetBudgetProblemSpotsQueryVariables>,
  "query"
> &
  ({ variables: GetBudgetProblemSpotsQueryVariables; skip?: false } | { skip: true });

export const GetBudgetProblemSpotsComponent = (props: GetBudgetProblemSpotsComponentProps) => (
  <ReactApollo.Query<GetBudgetProblemSpotsQuery, GetBudgetProblemSpotsQueryVariables> query={GetBudgetProblemSpotsDocument} {...props} />
);

export function useGetBudgetProblemSpotsQuery(baseOptions?: ReactApolloHooks.QueryHookOptions<GetBudgetProblemSpotsQueryVariables>) {
  return ReactApolloHooks.useQuery<GetBudgetProblemSpotsQuery, GetBudgetProblemSpotsQueryVariables>(
    GetBudgetProblemSpotsDocument,
    baseOptions
  );
}
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
export const UpdateProcessExecutionTodosPageDocument = gql`
  mutation UpdateProcessExecutionTodosPage($id: ID!, $attributes: ProcessExecutionAttributes!) {
    updateProcessExecution(id: $id, attributes: $attributes) {
      processExecution {
        id
        updatedAt
      }
      errors {
        fullMessage
      }
    }
  }
`;
export type UpdateProcessExecutionTodosPageMutationFn = ReactApollo.MutationFn<
  UpdateProcessExecutionTodosPageMutation,
  UpdateProcessExecutionTodosPageMutationVariables
>;
export type UpdateProcessExecutionTodosPageComponentProps = Omit<
  ReactApollo.MutationProps<UpdateProcessExecutionTodosPageMutation, UpdateProcessExecutionTodosPageMutationVariables>,
  "mutation"
>;

export const UpdateProcessExecutionTodosPageComponent = (props: UpdateProcessExecutionTodosPageComponentProps) => (
  <ReactApollo.Mutation<UpdateProcessExecutionTodosPageMutation, UpdateProcessExecutionTodosPageMutationVariables>
    mutation={UpdateProcessExecutionTodosPageDocument}
    {...props}
  />
);

export function useUpdateProcessExecutionTodosPageMutation(
  baseOptions?: ReactApolloHooks.MutationHookOptions<
    UpdateProcessExecutionTodosPageMutation,
    UpdateProcessExecutionTodosPageMutationVariables
  >
) {
  return ReactApolloHooks.useMutation<UpdateProcessExecutionTodosPageMutation, UpdateProcessExecutionTodosPageMutationVariables>(
    UpdateProcessExecutionTodosPageDocument,
    baseOptions
  );
}
export const CreateNewProcessTemplateDocument = gql`
  mutation CreateNewProcessTemplate {
    createProcessTemplate {
      processTemplate {
        id
      }
      errors {
        fullMessage
      }
    }
  }
`;
export type CreateNewProcessTemplateMutationFn = ReactApollo.MutationFn<
  CreateNewProcessTemplateMutation,
  CreateNewProcessTemplateMutationVariables
>;
export type CreateNewProcessTemplateComponentProps = Omit<
  ReactApollo.MutationProps<CreateNewProcessTemplateMutation, CreateNewProcessTemplateMutationVariables>,
  "mutation"
>;

export const CreateNewProcessTemplateComponent = (props: CreateNewProcessTemplateComponentProps) => (
  <ReactApollo.Mutation<CreateNewProcessTemplateMutation, CreateNewProcessTemplateMutationVariables>
    mutation={CreateNewProcessTemplateDocument}
    {...props}
  />
);

export function useCreateNewProcessTemplateMutation(
  baseOptions?: ReactApolloHooks.MutationHookOptions<CreateNewProcessTemplateMutation, CreateNewProcessTemplateMutationVariables>
) {
  return ReactApolloHooks.useMutation<CreateNewProcessTemplateMutation, CreateNewProcessTemplateMutationVariables>(
    CreateNewProcessTemplateDocument,
    baseOptions
  );
}
export const GetProcessTemplateForEditDocument = gql`
  query GetProcessTemplateForEdit($id: ID!) {
    processTemplate(id: $id) {
      id
      name
      document
      createdAt
      updatedAt
    }
    ...ContextForTodoEditor
  }
  ${ContextForTodoEditorFragmentDoc}
`;
export type GetProcessTemplateForEditComponentProps = Omit<
  ReactApollo.QueryProps<GetProcessTemplateForEditQuery, GetProcessTemplateForEditQueryVariables>,
  "query"
> &
  ({ variables: GetProcessTemplateForEditQueryVariables; skip?: false } | { skip: true });

export const GetProcessTemplateForEditComponent = (props: GetProcessTemplateForEditComponentProps) => (
  <ReactApollo.Query<GetProcessTemplateForEditQuery, GetProcessTemplateForEditQueryVariables>
    query={GetProcessTemplateForEditDocument}
    {...props}
  />
);

export function useGetProcessTemplateForEditQuery(
  baseOptions?: ReactApolloHooks.QueryHookOptions<GetProcessTemplateForEditQueryVariables>
) {
  return ReactApolloHooks.useQuery<GetProcessTemplateForEditQuery, GetProcessTemplateForEditQueryVariables>(
    GetProcessTemplateForEditDocument,
    baseOptions
  );
}
export const UpdateProcessTemplateDocument = gql`
  mutation UpdateProcessTemplate($id: ID!, $attributes: ProcessTemplateAttributes!) {
    updateProcessTemplate(id: $id, attributes: $attributes) {
      processTemplate {
        id
        updatedAt
      }
      errors {
        fullMessage
      }
    }
  }
`;
export type UpdateProcessTemplateMutationFn = ReactApollo.MutationFn<UpdateProcessTemplateMutation, UpdateProcessTemplateMutationVariables>;
export type UpdateProcessTemplateComponentProps = Omit<
  ReactApollo.MutationProps<UpdateProcessTemplateMutation, UpdateProcessTemplateMutationVariables>,
  "mutation"
>;

export const UpdateProcessTemplateComponent = (props: UpdateProcessTemplateComponentProps) => (
  <ReactApollo.Mutation<UpdateProcessTemplateMutation, UpdateProcessTemplateMutationVariables>
    mutation={UpdateProcessTemplateDocument}
    {...props}
  />
);

export function useUpdateProcessTemplateMutation(
  baseOptions?: ReactApolloHooks.MutationHookOptions<UpdateProcessTemplateMutation, UpdateProcessTemplateMutationVariables>
) {
  return ReactApolloHooks.useMutation<UpdateProcessTemplateMutation, UpdateProcessTemplateMutationVariables>(
    UpdateProcessTemplateDocument,
    baseOptions
  );
}
export const GetProcessExecutionForEditDocument = gql`
  query GetProcessExecutionForEdit($id: ID!) {
    processExecution(id: $id) {
      id
      name
      startedAt
      document
      processTemplate {
        id
        name
      }
      createdAt
      updatedAt
    }
    ...ContextForTodoEditor
  }
  ${ContextForTodoEditorFragmentDoc}
`;
export type GetProcessExecutionForEditComponentProps = Omit<
  ReactApollo.QueryProps<GetProcessExecutionForEditQuery, GetProcessExecutionForEditQueryVariables>,
  "query"
> &
  ({ variables: GetProcessExecutionForEditQueryVariables; skip?: false } | { skip: true });

export const GetProcessExecutionForEditComponent = (props: GetProcessExecutionForEditComponentProps) => (
  <ReactApollo.Query<GetProcessExecutionForEditQuery, GetProcessExecutionForEditQueryVariables>
    query={GetProcessExecutionForEditDocument}
    {...props}
  />
);

export function useGetProcessExecutionForEditQuery(
  baseOptions?: ReactApolloHooks.QueryHookOptions<GetProcessExecutionForEditQueryVariables>
) {
  return ReactApolloHooks.useQuery<GetProcessExecutionForEditQuery, GetProcessExecutionForEditQueryVariables>(
    GetProcessExecutionForEditDocument,
    baseOptions
  );
}
export const UpdateProcessExecutionDocument = gql`
  mutation UpdateProcessExecution($id: ID!, $attributes: ProcessExecutionAttributes!) {
    updateProcessExecution(id: $id, attributes: $attributes) {
      processExecution {
        id
        updatedAt
      }
      errors {
        fullMessage
      }
    }
  }
`;
export type UpdateProcessExecutionMutationFn = ReactApollo.MutationFn<
  UpdateProcessExecutionMutation,
  UpdateProcessExecutionMutationVariables
>;
export type UpdateProcessExecutionComponentProps = Omit<
  ReactApollo.MutationProps<UpdateProcessExecutionMutation, UpdateProcessExecutionMutationVariables>,
  "mutation"
>;

export const UpdateProcessExecutionComponent = (props: UpdateProcessExecutionComponentProps) => (
  <ReactApollo.Mutation<UpdateProcessExecutionMutation, UpdateProcessExecutionMutationVariables>
    mutation={UpdateProcessExecutionDocument}
    {...props}
  />
);

export function useUpdateProcessExecutionMutation(
  baseOptions?: ReactApolloHooks.MutationHookOptions<UpdateProcessExecutionMutation, UpdateProcessExecutionMutationVariables>
) {
  return ReactApolloHooks.useMutation<UpdateProcessExecutionMutation, UpdateProcessExecutionMutationVariables>(
    UpdateProcessExecutionDocument,
    baseOptions
  );
}
export const GetAllProcessTemplatesDocument = gql`
  query GetAllProcessTemplates {
    processTemplates(first: 30) {
      nodes {
        id
        key: id
        name
        creator {
          ...UserCard
        }
        lastExecution {
          id
          startedAt
          createdAt
        }
      }
    }
  }
  ${UserCardFragmentDoc}
`;
export type GetAllProcessTemplatesComponentProps = Omit<
  ReactApollo.QueryProps<GetAllProcessTemplatesQuery, GetAllProcessTemplatesQueryVariables>,
  "query"
>;

export const GetAllProcessTemplatesComponent = (props: GetAllProcessTemplatesComponentProps) => (
  <ReactApollo.Query<GetAllProcessTemplatesQuery, GetAllProcessTemplatesQueryVariables> query={GetAllProcessTemplatesDocument} {...props} />
);

export function useGetAllProcessTemplatesQuery(baseOptions?: ReactApolloHooks.QueryHookOptions<GetAllProcessTemplatesQueryVariables>) {
  return ReactApolloHooks.useQuery<GetAllProcessTemplatesQuery, GetAllProcessTemplatesQueryVariables>(
    GetAllProcessTemplatesDocument,
    baseOptions
  );
}
export const DiscardProcessTemplateDocument = gql`
  mutation DiscardProcessTemplate($id: ID!) {
    discardProcessTemplate(id: $id) {
      processTemplate {
        id
        discardedAt
      }
      errors {
        fullMessage
      }
    }
  }
`;
export type DiscardProcessTemplateMutationFn = ReactApollo.MutationFn<
  DiscardProcessTemplateMutation,
  DiscardProcessTemplateMutationVariables
>;
export type DiscardProcessTemplateComponentProps = Omit<
  ReactApollo.MutationProps<DiscardProcessTemplateMutation, DiscardProcessTemplateMutationVariables>,
  "mutation"
>;

export const DiscardProcessTemplateComponent = (props: DiscardProcessTemplateComponentProps) => (
  <ReactApollo.Mutation<DiscardProcessTemplateMutation, DiscardProcessTemplateMutationVariables>
    mutation={DiscardProcessTemplateDocument}
    {...props}
  />
);

export function useDiscardProcessTemplateMutation(
  baseOptions?: ReactApolloHooks.MutationHookOptions<DiscardProcessTemplateMutation, DiscardProcessTemplateMutationVariables>
) {
  return ReactApolloHooks.useMutation<DiscardProcessTemplateMutation, DiscardProcessTemplateMutationVariables>(
    DiscardProcessTemplateDocument,
    baseOptions
  );
}
export const GetAllProcessExecutionsDocument = gql`
  query GetAllProcessExecutions {
    processExecutions(first: 30) {
      nodes {
        id
        key: id
        name
        startedAt
        openTodoCount
        closedTodoCount
        totalTodoCount
        closestFutureDeadline
        involvedUsers {
          ...UserCard
        }
      }
    }
  }
  ${UserCardFragmentDoc}
`;
export type GetAllProcessExecutionsComponentProps = Omit<
  ReactApollo.QueryProps<GetAllProcessExecutionsQuery, GetAllProcessExecutionsQueryVariables>,
  "query"
>;

export const GetAllProcessExecutionsComponent = (props: GetAllProcessExecutionsComponentProps) => (
  <ReactApollo.Query<GetAllProcessExecutionsQuery, GetAllProcessExecutionsQueryVariables>
    query={GetAllProcessExecutionsDocument}
    {...props}
  />
);

export function useGetAllProcessExecutionsQuery(baseOptions?: ReactApolloHooks.QueryHookOptions<GetAllProcessExecutionsQueryVariables>) {
  return ReactApolloHooks.useQuery<GetAllProcessExecutionsQuery, GetAllProcessExecutionsQueryVariables>(
    GetAllProcessExecutionsDocument,
    baseOptions
  );
}
export const CreateNewProcessExecutionDocument = gql`
  mutation CreateNewProcessExecution {
    createProcessExecution {
      processExecution {
        id
      }
      errors {
        fullMessage
      }
    }
  }
`;
export type CreateNewProcessExecutionMutationFn = ReactApollo.MutationFn<
  CreateNewProcessExecutionMutation,
  CreateNewProcessExecutionMutationVariables
>;
export type CreateNewProcessExecutionComponentProps = Omit<
  ReactApollo.MutationProps<CreateNewProcessExecutionMutation, CreateNewProcessExecutionMutationVariables>,
  "mutation"
>;

export const CreateNewProcessExecutionComponent = (props: CreateNewProcessExecutionComponentProps) => (
  <ReactApollo.Mutation<CreateNewProcessExecutionMutation, CreateNewProcessExecutionMutationVariables>
    mutation={CreateNewProcessExecutionDocument}
    {...props}
  />
);

export function useCreateNewProcessExecutionMutation(
  baseOptions?: ReactApolloHooks.MutationHookOptions<CreateNewProcessExecutionMutation, CreateNewProcessExecutionMutationVariables>
) {
  return ReactApolloHooks.useMutation<CreateNewProcessExecutionMutation, CreateNewProcessExecutionMutationVariables>(
    CreateNewProcessExecutionDocument,
    baseOptions
  );
}
export const DiscardProcessExecutionDocument = gql`
  mutation DiscardProcessExecution($id: ID!) {
    discardProcessExecution(id: $id) {
      processExecution {
        id
        discardedAt
      }
      errors {
        fullMessage
      }
    }
  }
`;
export type DiscardProcessExecutionMutationFn = ReactApollo.MutationFn<
  DiscardProcessExecutionMutation,
  DiscardProcessExecutionMutationVariables
>;
export type DiscardProcessExecutionComponentProps = Omit<
  ReactApollo.MutationProps<DiscardProcessExecutionMutation, DiscardProcessExecutionMutationVariables>,
  "mutation"
>;

export const DiscardProcessExecutionComponent = (props: DiscardProcessExecutionComponentProps) => (
  <ReactApollo.Mutation<DiscardProcessExecutionMutation, DiscardProcessExecutionMutationVariables>
    mutation={DiscardProcessExecutionDocument}
    {...props}
  />
);

export function useDiscardProcessExecutionMutation(
  baseOptions?: ReactApolloHooks.MutationHookOptions<DiscardProcessExecutionMutation, DiscardProcessExecutionMutationVariables>
) {
  return ReactApolloHooks.useMutation<DiscardProcessExecutionMutation, DiscardProcessExecutionMutationVariables>(
    DiscardProcessExecutionDocument,
    baseOptions
  );
}
export const UpdateScratchpadFromFormDocument = gql`
  mutation UpdateScratchpadFromForm($id: ID!, $attributes: ScratchpadAttributes!) {
    updateScratchpad(id: $id, attributes: $attributes) {
      scratchpad {
        id
        name
        updatedAt
      }
      errors {
        fullMessage
      }
    }
  }
`;
export type UpdateScratchpadFromFormMutationFn = ReactApollo.MutationFn<
  UpdateScratchpadFromFormMutation,
  UpdateScratchpadFromFormMutationVariables
>;
export type UpdateScratchpadFromFormComponentProps = Omit<
  ReactApollo.MutationProps<UpdateScratchpadFromFormMutation, UpdateScratchpadFromFormMutationVariables>,
  "mutation"
>;

export const UpdateScratchpadFromFormComponent = (props: UpdateScratchpadFromFormComponentProps) => (
  <ReactApollo.Mutation<UpdateScratchpadFromFormMutation, UpdateScratchpadFromFormMutationVariables>
    mutation={UpdateScratchpadFromFormDocument}
    {...props}
  />
);

export function useUpdateScratchpadFromFormMutation(
  baseOptions?: ReactApolloHooks.MutationHookOptions<UpdateScratchpadFromFormMutation, UpdateScratchpadFromFormMutationVariables>
) {
  return ReactApolloHooks.useMutation<UpdateScratchpadFromFormMutation, UpdateScratchpadFromFormMutationVariables>(
    UpdateScratchpadFromFormDocument,
    baseOptions
  );
}
export const GetProcessTemplateForStartDocument = gql`
  query GetProcessTemplateForStart($id: ID!) {
    processTemplate(id: $id) {
      id
      name
      document
      createdAt
      updatedAt
      executionCount
    }
    ...ContextForTodoEditor
  }
  ${ContextForTodoEditorFragmentDoc}
`;
export type GetProcessTemplateForStartComponentProps = Omit<
  ReactApollo.QueryProps<GetProcessTemplateForStartQuery, GetProcessTemplateForStartQueryVariables>,
  "query"
> &
  ({ variables: GetProcessTemplateForStartQueryVariables; skip?: false } | { skip: true });

export const GetProcessTemplateForStartComponent = (props: GetProcessTemplateForStartComponentProps) => (
  <ReactApollo.Query<GetProcessTemplateForStartQuery, GetProcessTemplateForStartQueryVariables>
    query={GetProcessTemplateForStartDocument}
    {...props}
  />
);

export function useGetProcessTemplateForStartQuery(
  baseOptions?: ReactApolloHooks.QueryHookOptions<GetProcessTemplateForStartQueryVariables>
) {
  return ReactApolloHooks.useQuery<GetProcessTemplateForStartQuery, GetProcessTemplateForStartQueryVariables>(
    GetProcessTemplateForStartDocument,
    baseOptions
  );
}
export const StartProcessExecutionDocument = gql`
  mutation StartProcessExecution($attributes: ProcessExecutionAttributes!) {
    createProcessExecution(attributes: $attributes) {
      processExecution {
        id
        updatedAt
      }
      errors {
        fullMessage
      }
    }
  }
`;
export type StartProcessExecutionMutationFn = ReactApollo.MutationFn<StartProcessExecutionMutation, StartProcessExecutionMutationVariables>;
export type StartProcessExecutionComponentProps = Omit<
  ReactApollo.MutationProps<StartProcessExecutionMutation, StartProcessExecutionMutationVariables>,
  "mutation"
>;

export const StartProcessExecutionComponent = (props: StartProcessExecutionComponentProps) => (
  <ReactApollo.Mutation<StartProcessExecutionMutation, StartProcessExecutionMutationVariables>
    mutation={StartProcessExecutionDocument}
    {...props}
  />
);

export function useStartProcessExecutionMutation(
  baseOptions?: ReactApolloHooks.MutationHookOptions<StartProcessExecutionMutation, StartProcessExecutionMutationVariables>
) {
  return ReactApolloHooks.useMutation<StartProcessExecutionMutation, StartProcessExecutionMutationVariables>(
    StartProcessExecutionDocument,
    baseOptions
  );
}
export const GetScratchpadForSharingDocument = gql`
  query GetScratchpadForSharing($id: ID!) {
    scratchpad(id: $id) {
      id
      accessMode
    }
  }
`;
export type GetScratchpadForSharingComponentProps = Omit<
  ReactApollo.QueryProps<GetScratchpadForSharingQuery, GetScratchpadForSharingQueryVariables>,
  "query"
> &
  ({ variables: GetScratchpadForSharingQueryVariables; skip?: false } | { skip: true });

export const GetScratchpadForSharingComponent = (props: GetScratchpadForSharingComponentProps) => (
  <ReactApollo.Query<GetScratchpadForSharingQuery, GetScratchpadForSharingQueryVariables>
    query={GetScratchpadForSharingDocument}
    {...props}
  />
);

export function useGetScratchpadForSharingQuery(baseOptions?: ReactApolloHooks.QueryHookOptions<GetScratchpadForSharingQueryVariables>) {
  return ReactApolloHooks.useQuery<GetScratchpadForSharingQuery, GetScratchpadForSharingQueryVariables>(
    GetScratchpadForSharingDocument,
    baseOptions
  );
}
export const SetScratchpadSharingDocument = gql`
  mutation SetScratchpadSharing($id: ID!, $attributes: ScratchpadAttributes!) {
    updateScratchpad(id: $id, attributes: $attributes) {
      scratchpad {
        id
        accessMode
      }
      errors {
        fullMessage
      }
    }
  }
`;
export type SetScratchpadSharingMutationFn = ReactApollo.MutationFn<SetScratchpadSharingMutation, SetScratchpadSharingMutationVariables>;
export type SetScratchpadSharingComponentProps = Omit<
  ReactApollo.MutationProps<SetScratchpadSharingMutation, SetScratchpadSharingMutationVariables>,
  "mutation"
>;

export const SetScratchpadSharingComponent = (props: SetScratchpadSharingComponentProps) => (
  <ReactApollo.Mutation<SetScratchpadSharingMutation, SetScratchpadSharingMutationVariables>
    mutation={SetScratchpadSharingDocument}
    {...props}
  />
);

export function useSetScratchpadSharingMutation(
  baseOptions?: ReactApolloHooks.MutationHookOptions<SetScratchpadSharingMutation, SetScratchpadSharingMutationVariables>
) {
  return ReactApolloHooks.useMutation<SetScratchpadSharingMutation, SetScratchpadSharingMutationVariables>(
    SetScratchpadSharingDocument,
    baseOptions
  );
}
export const ToolbarDiscardScratchpadDocument = gql`
  mutation ToolbarDiscardScratchpad($id: ID!) {
    discardScratchpad(id: $id) {
      scratchpad {
        id
        discardedAt
      }
      errors {
        fullMessage
      }
    }
  }
`;
export type ToolbarDiscardScratchpadMutationFn = ReactApollo.MutationFn<
  ToolbarDiscardScratchpadMutation,
  ToolbarDiscardScratchpadMutationVariables
>;
export type ToolbarDiscardScratchpadComponentProps = Omit<
  ReactApollo.MutationProps<ToolbarDiscardScratchpadMutation, ToolbarDiscardScratchpadMutationVariables>,
  "mutation"
>;

export const ToolbarDiscardScratchpadComponent = (props: ToolbarDiscardScratchpadComponentProps) => (
  <ReactApollo.Mutation<ToolbarDiscardScratchpadMutation, ToolbarDiscardScratchpadMutationVariables>
    mutation={ToolbarDiscardScratchpadDocument}
    {...props}
  />
);

export function useToolbarDiscardScratchpadMutation(
  baseOptions?: ReactApolloHooks.MutationHookOptions<ToolbarDiscardScratchpadMutation, ToolbarDiscardScratchpadMutationVariables>
) {
  return ReactApolloHooks.useMutation<ToolbarDiscardScratchpadMutation, ToolbarDiscardScratchpadMutationVariables>(
    ToolbarDiscardScratchpadDocument,
    baseOptions
  );
}
export const GetMyTodosDocument = gql`
  query GetMyTodos($after: String) {
    currentUser {
      id
      todoFeedItems(first: 30, after: $after) {
        pageInfo {
          endCursor
          hasNextPage
        }
        edges {
          node {
            id
            updatedAt
            todoSource {
              __typename
              ... on ProcessExecution {
                id
                name
                involvedUsers {
                  ...UserCard
                }
              }
              ... on Scratchpad {
                id
                name
              }
            }
          }
        }
      }
    }
    ...ContextForTodoEditor
  }
  ${UserCardFragmentDoc}
  ${ContextForTodoEditorFragmentDoc}
`;
export type GetMyTodosComponentProps = Omit<ReactApollo.QueryProps<GetMyTodosQuery, GetMyTodosQueryVariables>, "query">;

export const GetMyTodosComponent = (props: GetMyTodosComponentProps) => (
  <ReactApollo.Query<GetMyTodosQuery, GetMyTodosQueryVariables> query={GetMyTodosDocument} {...props} />
);

export function useGetMyTodosQuery(baseOptions?: ReactApolloHooks.QueryHookOptions<GetMyTodosQueryVariables>) {
  return ReactApolloHooks.useQuery<GetMyTodosQuery, GetMyTodosQueryVariables>(GetMyTodosDocument, baseOptions);
}
export const GetProcessExecutionForTodosDocument = gql`
  query GetProcessExecutionForTodos($id: ID!) {
    processExecution(id: $id) {
      name
      ...CondensedProcessExecutionForm
    }
  }
  ${CondensedProcessExecutionFormFragmentDoc}
`;
export type GetProcessExecutionForTodosComponentProps = Omit<
  ReactApollo.QueryProps<GetProcessExecutionForTodosQuery, GetProcessExecutionForTodosQueryVariables>,
  "query"
> &
  ({ variables: GetProcessExecutionForTodosQueryVariables; skip?: false } | { skip: true });

export const GetProcessExecutionForTodosComponent = (props: GetProcessExecutionForTodosComponentProps) => (
  <ReactApollo.Query<GetProcessExecutionForTodosQuery, GetProcessExecutionForTodosQueryVariables>
    query={GetProcessExecutionForTodosDocument}
    {...props}
  />
);

export function useGetProcessExecutionForTodosQuery(
  baseOptions?: ReactApolloHooks.QueryHookOptions<GetProcessExecutionForTodosQueryVariables>
) {
  return ReactApolloHooks.useQuery<GetProcessExecutionForTodosQuery, GetProcessExecutionForTodosQueryVariables>(
    GetProcessExecutionForTodosDocument,
    baseOptions
  );
}
export const GetScratchpadForTodosDocument = gql`
  query GetScratchpadForTodos($id: ID!) {
    scratchpad(id: $id) {
      id
      ...ScratchpadForm
    }
  }
  ${ScratchpadFormFragmentDoc}
`;
export type GetScratchpadForTodosComponentProps = Omit<
  ReactApollo.QueryProps<GetScratchpadForTodosQuery, GetScratchpadForTodosQueryVariables>,
  "query"
> &
  ({ variables: GetScratchpadForTodosQueryVariables; skip?: false } | { skip: true });

export const GetScratchpadForTodosComponent = (props: GetScratchpadForTodosComponentProps) => (
  <ReactApollo.Query<GetScratchpadForTodosQuery, GetScratchpadForTodosQueryVariables> query={GetScratchpadForTodosDocument} {...props} />
);

export function useGetScratchpadForTodosQuery(baseOptions?: ReactApolloHooks.QueryHookOptions<GetScratchpadForTodosQueryVariables>) {
  return ReactApolloHooks.useQuery<GetScratchpadForTodosQuery, GetScratchpadForTodosQueryVariables>(
    GetScratchpadForTodosDocument,
    baseOptions
  );
}
export const CreateNewScratchpadDocument = gql`
  mutation CreateNewScratchpad {
    createScratchpad {
      scratchpad {
        id
        ...ScratchpadForm
      }
      errors {
        fullMessage
      }
    }
  }
  ${ScratchpadFormFragmentDoc}
`;
export type CreateNewScratchpadMutationFn = ReactApollo.MutationFn<CreateNewScratchpadMutation, CreateNewScratchpadMutationVariables>;
export type CreateNewScratchpadComponentProps = Omit<
  ReactApollo.MutationProps<CreateNewScratchpadMutation, CreateNewScratchpadMutationVariables>,
  "mutation"
>;

export const CreateNewScratchpadComponent = (props: CreateNewScratchpadComponentProps) => (
  <ReactApollo.Mutation<CreateNewScratchpadMutation, CreateNewScratchpadMutationVariables>
    mutation={CreateNewScratchpadDocument}
    {...props}
  />
);

export function useCreateNewScratchpadMutation(
  baseOptions?: ReactApolloHooks.MutationHookOptions<CreateNewScratchpadMutation, CreateNewScratchpadMutationVariables>
) {
  return ReactApolloHooks.useMutation<CreateNewScratchpadMutation, CreateNewScratchpadMutationVariables>(
    CreateNewScratchpadDocument,
    baseOptions
  );
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
