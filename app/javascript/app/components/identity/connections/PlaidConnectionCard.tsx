import React from "react";
import gql from "graphql-tag";
import { Settings } from "app/lib/settings";
import { PlaidLink } from "../PlaidLink";
import { ConnectionCard } from "./ConnectionCard";
import { useConnectPlaidMutation } from "app/app-graph";
import { mutationSuccess, toast } from "superlib";

gql`
  mutation ConnectPlaid($publicToken: String!) {
    connectPlaid(publicToken: $publicToken) {
      plaidItem {
        id
        accounts {
          name
          type
          subtype
        }
      }
    }
  }
`;

export const PlaidConnectionCard = (_props: {}) => {
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
    <ConnectionCard name="Plaid" description="Plaid is a blah blah blah">
      <PlaidLink
        clientName="Superpro"
        env={Settings.plaid.env as any}
        publicKey={Settings.plaid.publicKey}
        product={["auth", "transactions"]}
        webhook={Settings.plaid.webhookUrl}
        style={{ outline: "none", border: "0px", background: "#FFFFFF" }}
        onSuccess={onSuccess}
        onExit={() => toast.error("There was an error connecting Plaid. Please try again.")}
        label="Connect Plaid"
      />
    </ConnectionCard>
  );
};
