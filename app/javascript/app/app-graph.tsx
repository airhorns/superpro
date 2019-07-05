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

export type AppMutation = {
  __typename?: "AppMutation";
  createProcessExecution?: Maybe<CreateProcessExecutionPayload>;
  createProcessTemplate?: Maybe<CreateProcessTemplatePayload>;
  discardProcessExecution?: Maybe<DiscardProcessExecutionPayload>;
  discardProcessTemplate?: Maybe<DiscardProcessTemplatePayload>;
  updateBudget?: Maybe<UpdateBudgetPayload>;
  updateProcessExecution?: Maybe<UpdateProcessExecutionPayload>;
  updateProcessTemplate?: Maybe<UpdateProcessTemplatePayload>;
};

export type AppMutationCreateProcessExecutionArgs = {
  attributes?: Maybe<ProcessExecutionAttributes>;
};

export type AppMutationCreateProcessTemplateArgs = {
  attributes?: Maybe<ProcessTemplateAttributes>;
};

export type AppMutationDiscardProcessExecutionArgs = {
  id: Scalars["ID"];
};

export type AppMutationDiscardProcessTemplateArgs = {
  id: Scalars["ID"];
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

export type AppQuery = {
  __typename?: "AppQuery";
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

export type AppQueryUsersArgs = {
  after?: Maybe<Scalars["String"]>;
  before?: Maybe<Scalars["String"]>;
  first?: Maybe<Scalars["Int"]>;
  last?: Maybe<Scalars["Int"]>;
};

export type Budget = {
  __typename?: "Budget";
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
  __typename?: "BudgetConnection";
  /** A list of edges. */
  edges: Array<BudgetEdge>;
  /** A list of nodes. */
  nodes: Array<Budget>;
  /** Information to aid in pagination. */
  pageInfo: PageInfo;
};

/** An edge in a connection. */
export type BudgetEdge = {
  __typename?: "BudgetEdge";
  /** A cursor for use in pagination. */
  cursor: Scalars["String"];
  /** The item at the end of the edge. */
  node?: Maybe<Budget>;
};

export type BudgetLine = {
  __typename?: "BudgetLine";
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
  __typename?: "BudgetLineFixedValue";
  amountScenarios: Scalars["JSONScalar"];
  occursAt: Scalars["ISO8601DateTime"];
  recurrenceRules?: Maybe<Array<Scalars["RecurrenceRuleString"]>>;
  type: Scalars["String"];
};

export type BudgetLineSeriesCell = {
  __typename?: "BudgetLineSeriesCell";
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
  __typename?: "BudgetLineSeriesValue";
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
  __typename?: "BudgetProblemSpot";
  endDate: Scalars["ISO8601DateTime"];
  minCashOnHand: Money;
  scenario: Scalars["String"];
  spotNumber: Scalars["Int"];
  startDate: Scalars["ISO8601DateTime"];
};

/** Autogenerated return type of CreateProcessExecution */
export type CreateProcessExecutionPayload = {
  __typename?: "CreateProcessExecutionPayload";
  errors?: Maybe<Array<MutationError>>;
  processExecution?: Maybe<ProcessExecution>;
};

/** Autogenerated return type of CreateProcessTemplate */
export type CreateProcessTemplatePayload = {
  __typename?: "CreateProcessTemplatePayload";
  errors?: Maybe<Array<MutationError>>;
  processTemplate?: Maybe<ProcessTemplate>;
};

export type Currency = {
  __typename?: "Currency";
  decimalMark: Scalars["String"];
  isoCode: Scalars["String"];
  name: Scalars["String"];
  symbol: Scalars["String"];
  symbolFirst: Scalars["Boolean"];
  thousandsSeparator: Scalars["String"];
};

/** Autogenerated return type of DiscardProcessExecution */
export type DiscardProcessExecutionPayload = {
  __typename?: "DiscardProcessExecutionPayload";
  errors?: Maybe<Array<MutationError>>;
  processExecution?: Maybe<ProcessExecution>;
};

/** Autogenerated return type of DiscardProcessTemplate */
export type DiscardProcessTemplatePayload = {
  __typename?: "DiscardProcessTemplatePayload";
  errors?: Maybe<Array<MutationError>>;
  processTemplate?: Maybe<ProcessTemplate>;
};

export type Money = {
  __typename?: "Money";
  currency: Currency;
  formatted: Scalars["String"];
  fractional: Scalars["Int"];
};

/** Error object describing a reason why a mutation was unsuccessful, specific to a particular field. */
export type MutationError = {
  __typename?: "MutationError";
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
  __typename?: "PageInfo";
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
  __typename?: "ProcessExecution";
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
  __typename?: "ProcessExecutionConnection";
  /** A list of edges. */
  edges: Array<ProcessExecutionEdge>;
  /** A list of nodes. */
  nodes: Array<ProcessExecution>;
  /** Information to aid in pagination. */
  pageInfo: PageInfo;
};

/** An edge in a connection. */
export type ProcessExecutionEdge = {
  __typename?: "ProcessExecutionEdge";
  /** A cursor for use in pagination. */
  cursor: Scalars["String"];
  /** The item at the end of the edge. */
  node?: Maybe<ProcessExecution>;
};

export type ProcessTemplate = {
  __typename?: "ProcessTemplate";
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
  __typename?: "ProcessTemplateConnection";
  /** A list of edges. */
  edges: Array<ProcessTemplateEdge>;
  /** A list of nodes. */
  nodes: Array<ProcessTemplate>;
  /** Information to aid in pagination. */
  pageInfo: PageInfo;
};

/** An edge in a connection. */
export type ProcessTemplateEdge = {
  __typename?: "ProcessTemplateEdge";
  /** A cursor for use in pagination. */
  cursor: Scalars["String"];
  /** The item at the end of the edge. */
  node?: Maybe<ProcessTemplate>;
};

/** Autogenerated return type of UpdateBudget */
export type UpdateBudgetPayload = {
  __typename?: "UpdateBudgetPayload";
  budget?: Maybe<Budget>;
  errors?: Maybe<Array<MutationError>>;
};

/** Autogenerated return type of UpdateProcessExecution */
export type UpdateProcessExecutionPayload = {
  __typename?: "UpdateProcessExecutionPayload";
  errors?: Maybe<Array<MutationError>>;
  processExecution?: Maybe<ProcessExecution>;
};

/** Autogenerated return type of UpdateProcessTemplate */
export type UpdateProcessTemplatePayload = {
  __typename?: "UpdateProcessTemplatePayload";
  errors?: Maybe<Array<MutationError>>;
  processTemplate?: Maybe<ProcessTemplate>;
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
  involvedProcessExecutions: ProcessExecutionConnection;
  locked: Scalars["Boolean"];
  updatedAt: Scalars["ISO8601DateTime"];
};

export type UserInvolvedProcessExecutionsArgs = {
  after?: Maybe<Scalars["String"]>;
  before?: Maybe<Scalars["String"]>;
  first?: Maybe<Scalars["Int"]>;
  last?: Maybe<Scalars["Int"]>;
};

/** The connection type for User. */
export type UserConnection = {
  __typename?: "UserConnection";
  /** A list of edges. */
  edges: Array<UserEdge>;
  /** A list of nodes. */
  nodes: Array<User>;
  /** Information to aid in pagination. */
  pageInfo: PageInfo;
};

/** An edge in a connection. */
export type UserEdge = {
  __typename?: "UserEdge";
  /** A cursor for use in pagination. */
  cursor: Scalars["String"];
  /** The item at the end of the edge. */
  node?: Maybe<User>;
};
export type GetBudgetForReportsQueryVariables = {};

export type GetBudgetForReportsQuery = { __typename?: "AppQuery" } & {
  budget: { __typename?: "Budget" } & Pick<Budget, "id" | "name" | "sections">;
};

export type BudgetForEditFragment = { __typename?: "Budget" } & Pick<Budget, "id" | "name"> & {
    budgetLines: Array<
      { __typename?: "BudgetLine" } & Pick<BudgetLine, "id" | "description" | "section" | "sortOrder"> & {
          value:
            | ({ __typename?: "BudgetLineFixedValue" } & Pick<
                BudgetLineFixedValue,
                "type" | "occursAt" | "recurrenceRules" | "amountScenarios"
              >)
            | ({ __typename?: "BudgetLineSeriesValue" } & Pick<BudgetLineSeriesValue, "type"> & {
                  cells: Array<{ __typename?: "BudgetLineSeriesCell" } & Pick<BudgetLineSeriesCell, "dateTime" | "amountScenarios">>;
                });
        }
    >;
  };

export type GetBudgetForEditQueryVariables = {};

export type GetBudgetForEditQuery = { __typename?: "AppQuery" } & { budget: { __typename?: "Budget" } & BudgetForEditFragment };

export type UpdateBudgetMutationVariables = {
  id: Scalars["ID"];
  attributes: BudgetAttributes;
};

export type UpdateBudgetMutation = { __typename?: "AppMutation" } & {
  updateBudget: Maybe<
    { __typename?: "UpdateBudgetPayload" } & {
      budget: Maybe<{ __typename?: "Budget" } & BudgetForEditFragment>;
      errors: Maybe<Array<{ __typename?: "MutationError" } & Pick<MutationError, "field" | "fullMessage">>>;
    }
  >;
};

export type GetBudgetProblemSpotsQueryVariables = {
  id: Scalars["ID"];
};

export type GetBudgetProblemSpotsQuery = { __typename?: "AppQuery" } & {
  budget: Maybe<
    { __typename?: "Budget" } & Pick<Budget, "id"> & {
        problemSpots: Array<
          { __typename?: "BudgetProblemSpot" } & Pick<BudgetProblemSpot, "startDate" | "endDate"> & {
              minCashOnHand: { __typename?: "Money" } & Pick<Money, "formatted">;
            }
        >;
      }
  >;
};

export type SiderInfoQueryVariables = {};

export type SiderInfoQuery = { __typename?: "AppQuery" } & {
  currentUser: { __typename?: "User" } & Pick<User, "email" | "fullName" | "authAreaUrl"> & UserCardFragment;
};

export type UserCardFragment = { __typename?: "User" } & Pick<User, "id" | "email" | "fullName">;

export type CondensedProcessExecutionFormFragment = { __typename?: "ProcessExecution" } & Pick<
  ProcessExecution,
  "id" | "document" | "name"
>;

export type UpdateProcessExecutionTodosPageMutationVariables = {
  id: Scalars["ID"];
  attributes: ProcessExecutionAttributes;
};

export type UpdateProcessExecutionTodosPageMutation = { __typename?: "AppMutation" } & {
  updateProcessExecution: Maybe<
    { __typename?: "UpdateProcessExecutionPayload" } & {
      processExecution: Maybe<{ __typename?: "ProcessExecution" } & Pick<ProcessExecution, "id" | "updatedAt">>;
      errors: Maybe<Array<{ __typename?: "MutationError" } & Pick<MutationError, "fullMessage">>>;
    }
  >;
};

export type GetProcessTemplateForEditQueryVariables = {
  id: Scalars["ID"];
};

export type GetProcessTemplateForEditQuery = { __typename?: "AppQuery" } & {
  processTemplate: Maybe<
    { __typename?: "ProcessTemplate" } & Pick<ProcessTemplate, "id" | "name" | "document" | "createdAt" | "updatedAt">
  >;
} & ContextForProcessEditorFragment;

export type UpdateProcessTemplateMutationVariables = {
  id: Scalars["ID"];
  attributes: ProcessTemplateAttributes;
};

export type UpdateProcessTemplateMutation = { __typename?: "AppMutation" } & {
  updateProcessTemplate: Maybe<
    { __typename?: "UpdateProcessTemplatePayload" } & {
      processTemplate: Maybe<{ __typename?: "ProcessTemplate" } & Pick<ProcessTemplate, "id" | "updatedAt">>;
      errors: Maybe<Array<{ __typename?: "MutationError" } & Pick<MutationError, "fullMessage">>>;
    }
  >;
};

export type GetProcessExecutionForEditQueryVariables = {
  id: Scalars["ID"];
};

export type GetProcessExecutionForEditQuery = { __typename?: "AppQuery" } & {
  processExecution: Maybe<
    { __typename?: "ProcessExecution" } & Pick<ProcessExecution, "id" | "name" | "startedAt" | "document" | "createdAt" | "updatedAt"> & {
        processTemplate: Maybe<{ __typename?: "ProcessTemplate" } & Pick<ProcessTemplate, "id" | "name">>;
      }
  >;
} & ContextForProcessEditorFragment;

export type UpdateProcessExecutionMutationVariables = {
  id: Scalars["ID"];
  attributes: ProcessExecutionAttributes;
};

export type UpdateProcessExecutionMutation = { __typename?: "AppMutation" } & {
  updateProcessExecution: Maybe<
    { __typename?: "UpdateProcessExecutionPayload" } & {
      processExecution: Maybe<{ __typename?: "ProcessExecution" } & Pick<ProcessExecution, "id" | "updatedAt">>;
      errors: Maybe<Array<{ __typename?: "MutationError" } & Pick<MutationError, "fullMessage">>>;
    }
  >;
};

export type ContextForProcessEditorFragment = { __typename?: "AppQuery" } & {
  users: { __typename?: "UserConnection" } & { nodes: Array<{ __typename?: "User" } & UserCardFragment> };
  currentUser: { __typename?: "User" } & Pick<User, "id">;
};

export type GetAllProcessTemplatesQueryVariables = {};

export type GetAllProcessTemplatesQuery = { __typename?: "AppQuery" } & {
  processTemplates: { __typename?: "ProcessTemplateConnection" } & {
    nodes: Array<
      { __typename?: "ProcessTemplate" } & Pick<ProcessTemplate, "id" | "name"> & { key: ProcessTemplate["id"] } & {
          creator: { __typename?: "User" } & UserCardFragment;
          lastExecution: Maybe<{ __typename?: "ProcessExecution" } & Pick<ProcessExecution, "id" | "startedAt" | "createdAt">>;
        }
    >;
  };
};

export type CreateNewProcessTemplateMutationVariables = {};

export type CreateNewProcessTemplateMutation = { __typename?: "AppMutation" } & {
  createProcessTemplate: Maybe<
    { __typename?: "CreateProcessTemplatePayload" } & {
      processTemplate: Maybe<{ __typename?: "ProcessTemplate" } & Pick<ProcessTemplate, "id">>;
      errors: Maybe<Array<{ __typename?: "MutationError" } & Pick<MutationError, "fullMessage">>>;
    }
  >;
};

export type DiscardProcessTemplateMutationVariables = {
  id: Scalars["ID"];
};

export type DiscardProcessTemplateMutation = { __typename?: "AppMutation" } & {
  discardProcessTemplate: Maybe<
    { __typename?: "DiscardProcessTemplatePayload" } & {
      processTemplate: Maybe<{ __typename?: "ProcessTemplate" } & Pick<ProcessTemplate, "id" | "discardedAt">>;
      errors: Maybe<Array<{ __typename?: "MutationError" } & Pick<MutationError, "fullMessage">>>;
    }
  >;
};

export type GetAllProcessExecutionsQueryVariables = {};

export type GetAllProcessExecutionsQuery = { __typename?: "AppQuery" } & {
  processExecutions: { __typename?: "ProcessExecutionConnection" } & {
    nodes: Array<
      { __typename?: "ProcessExecution" } & Pick<
        ProcessExecution,
        "id" | "name" | "startedAt" | "openTodoCount" | "closedTodoCount" | "totalTodoCount" | "closestFutureDeadline"
      > & { key: ProcessExecution["id"] } & { involvedUsers: Array<{ __typename?: "User" } & UserCardFragment> }
    >;
  };
};

export type CreateNewProcessExecutionMutationVariables = {};

export type CreateNewProcessExecutionMutation = { __typename?: "AppMutation" } & {
  createProcessExecution: Maybe<
    { __typename?: "CreateProcessExecutionPayload" } & {
      processExecution: Maybe<{ __typename?: "ProcessExecution" } & Pick<ProcessExecution, "id">>;
      errors: Maybe<Array<{ __typename?: "MutationError" } & Pick<MutationError, "fullMessage">>>;
    }
  >;
};

export type DiscardProcessExecutionMutationVariables = {
  id: Scalars["ID"];
};

export type DiscardProcessExecutionMutation = { __typename?: "AppMutation" } & {
  discardProcessExecution: Maybe<
    { __typename?: "DiscardProcessExecutionPayload" } & {
      processExecution: Maybe<{ __typename?: "ProcessExecution" } & Pick<ProcessExecution, "id" | "discardedAt">>;
      errors: Maybe<Array<{ __typename?: "MutationError" } & Pick<MutationError, "fullMessage">>>;
    }
  >;
};

export type GetProcessTemplateForStartQueryVariables = {
  id: Scalars["ID"];
};

export type GetProcessTemplateForStartQuery = { __typename?: "AppQuery" } & {
  processTemplate: Maybe<
    { __typename?: "ProcessTemplate" } & Pick<ProcessTemplate, "id" | "name" | "document" | "createdAt" | "updatedAt" | "executionCount">
  >;
} & ContextForProcessEditorFragment;

export type StartProcessExecutionMutationVariables = {
  attributes: ProcessExecutionAttributes;
};

export type StartProcessExecutionMutation = { __typename?: "AppMutation" } & {
  createProcessExecution: Maybe<
    { __typename?: "CreateProcessExecutionPayload" } & {
      processExecution: Maybe<{ __typename?: "ProcessExecution" } & Pick<ProcessExecution, "id" | "updatedAt">>;
      errors: Maybe<Array<{ __typename?: "MutationError" } & Pick<MutationError, "fullMessage">>>;
    }
  >;
};

export type GetMyTodosQueryVariables = {};

export type GetMyTodosQuery = { __typename?: "AppQuery" } & {
  currentUser: { __typename?: "User" } & Pick<User, "id"> & {
      involvedProcessExecutions: { __typename?: "ProcessExecutionConnection" } & {
        nodes: Array<{ __typename?: "ProcessExecution" } & Pick<ProcessExecution, "id" | "name"> & CondensedProcessExecutionFormFragment>;
      };
    };
} & ContextForProcessEditorFragment;
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
export const UserCardFragmentDoc = gql`
  fragment UserCard on User {
    id
    email
    fullName
  }
`;
export const ContextForProcessEditorFragmentDoc = gql`
  fragment ContextForProcessEditor on AppQuery {
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

export const GetProcessTemplateForEditDocument = gql`
  query GetProcessTemplateForEdit($id: ID!) {
    processTemplate(id: $id) {
      id
      name
      document
      createdAt
      updatedAt
    }
    ...ContextForProcessEditor
  }
  ${ContextForProcessEditorFragmentDoc}
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
    ...ContextForProcessEditor
  }
  ${ContextForProcessEditorFragmentDoc}
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
    ...ContextForProcessEditor
  }
  ${ContextForProcessEditorFragmentDoc}
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

export const GetMyTodosDocument = gql`
  query GetMyTodos {
    currentUser {
      id
      involvedProcessExecutions {
        nodes {
          id
          name
          ...CondensedProcessExecutionForm
        }
      }
    }
    ...ContextForProcessEditor
  }
  ${CondensedProcessExecutionFormFragmentDoc}
  ${ContextForProcessEditorFragmentDoc}
`;
export type GetMyTodosComponentProps = Omit<ReactApollo.QueryProps<GetMyTodosQuery, GetMyTodosQueryVariables>, "query">;

export const GetMyTodosComponent = (props: GetMyTodosComponentProps) => (
  <ReactApollo.Query<GetMyTodosQuery, GetMyTodosQueryVariables> query={GetMyTodosDocument} {...props} />
);
