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
  updateBudget?: Maybe<UpdateBudgetPayload>;
};

export type AppMutationUpdateBudgetArgs = {
  budgetId: Scalars["ID"];
  budget: BudgetAttributes;
};

export type AppQuery = {
  __typename?: "AppQuery";
  /** Find a budget by ID */
  budget?: Maybe<Budget>;
  /** Fetch all budgets in the system */
  budgets: Array<Budget>;
  /** Get the details of the current account */
  currentAccount: Account;
  /** Get the details of the currently logged in user */
  currentUser: User;
  /** Get the default budget premade for all accounts */
  defaultBudget: Budget;
};

export type AppQueryBudgetArgs = {
  budgetId: Scalars["ID"];
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

export type Currency = {
  __typename?: "Currency";
  decimalMark: Scalars["String"];
  isoCode: Scalars["String"];
  name: Scalars["String"];
  symbol: Scalars["String"];
  symbolFirst: Scalars["Boolean"];
  thousandsSeparator: Scalars["String"];
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

/** Autogenerated return type of UpdateBudget */
export type UpdateBudgetPayload = {
  __typename?: "UpdateBudgetPayload";
  budget?: Maybe<Budget>;
  errors?: Maybe<Array<MutationError>>;
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
  budgetId: Scalars["ID"];
  budget: BudgetAttributes;
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
  budgetId: Scalars["ID"];
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
  currentUser: { __typename?: "User" } & Pick<User, "email" | "fullName" | "authAreaUrl"> & {
      preferences: { __typename?: "UserPreferences" } & Pick<UserPreferences, "sidebarExpanded">;
    };
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
  mutation UpdateBudget($budgetId: ID!, $budget: BudgetAttributes!) {
    updateBudget(budgetId: $budgetId, budget: $budget) {
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
  query GetBudgetProblemSpots($budgetId: ID!) {
    budget(budgetId: $budgetId) {
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
      preferences {
        sidebarExpanded
      }
      authAreaUrl
    }
  }
`;
export type SiderInfoComponentProps = Omit<ReactApollo.QueryProps<SiderInfoQuery, SiderInfoQueryVariables>, "query">;

export const SiderInfoComponent = (props: SiderInfoComponentProps) => (
  <ReactApollo.Query<SiderInfoQuery, SiderInfoQueryVariables> query={SiderInfoDocument} {...props} />
);
