import React from "react";
import gql from "graphql-tag";
import { Settings } from "app/lib/settings";
import { PlaidLink } from "./PlaidLink";
import { ConnectionCard } from "./ConnectionCard";
import { useConnectPlaidMutation } from "app/app-graph";
import { mutationSuccess, toast } from "superlib";
import { Box, Text } from "grommet";
import { flatMap } from "lodash";

gql`
  fragment PlaidConnectionCardContent on PlaidItem {
    id
    accounts {
      id
      name
      type
    }
  }

  mutation ConnectPlaid($publicToken: String!) {
    connectPlaid(publicToken: $publicToken) {
      plaidItem {
        ...PlaidConnectionCardContent
      }
    }
  }
`;

interface PlaidItem {
  id: string;
  accounts: { id: string; name: string; type: string }[];
}

export const PlaidConnectionCard = (props: { plaidItems: PlaidItem[] }) => {
  const connectPlaid = useConnectPlaidMutation();
  const onSuccess = React.useCallback(
    async (publicToken: string) => {
      let success = false;
      let result;
      try {
        result = await connectPlaid({ variables: { publicToken } });
      } catch (e) {}

      const data = mutationSuccess(result, "connectPlaid");
      if (data) {
        success = true;
        toast.success("Plaid connected successfully.");
      }

      if (!success) {
        toast.error("There was an error connecting Plaid. Please try again.");
      }
    },
    [connectPlaid]
  );
  return (
    <ConnectionCard
      name="Direct Bank Accounts"
      description="Superpro can connect directly to your bank account to import transaction data for your budget. Superpro connects securely via our banking partner [Plaid](https://plaid.com/)."
    >
      {props.plaidItems.length > 0 && (
        <Box>
          <Text>Currently Connected Bank Accounts:</Text>
          <ul>
            {flatMap(props.plaidItems, item =>
              item.accounts.map(account => (
                <li key={account.id}>
                  {account.name} ({account.type})
                </li>
              ))
            )}
          </ul>
        </Box>
      )}
      <PlaidLink
        clientName="Superpro"
        env={Settings.plaid.env as any}
        publicKey={Settings.plaid.publicKey}
        product={["auth", "transactions"]}
        webhook={Settings.plaid.webhookUrl}
        style={{ outline: "none", border: "0px", background: "#FFFFFF" }}
        onSuccess={onSuccess}
        onExit={(error: any) => {
          if (error) {
            const message = error.display_message || "";
            toast.error(`There was an error connecting Plaid. ${message} Please try again.`);
          }
        }}
        label={`Connect ${(props.plaidItems.length > 0 && "Another ") || ""}Bank Account`}
      />
    </ConnectionCard>
  );
};
