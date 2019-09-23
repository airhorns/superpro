import React from "react";
import gql from "graphql-tag";
import { ConnectionCard } from "./ConnectionCard";
import { useConnectShopifyMutation, GetConnectionsIndexPageDocument } from "app/app-graph";
import { mutationSuccess, toast, SimpleModal } from "superlib";
import { Box, Heading, Button, Anchor, Tabs, Tab } from "grommet";
import { Add } from "app/components/common/SuperproIcons";
import { Input, FieldBox, SuperForm } from "superlib/superform";

gql`
  mutation ConnectShopify($apiKey: String!, $password: String!, $domain: String!) {
    connectShopify(apiKey: $apiKey, password: $password, domain: $domain) {
      errors
      shopifyShop {
        id
      }
    }
  }
`;

interface ShopifyShop {
  id: string;
  name: string;
  shopifyDomain: string;
  shopId: string;
  connection: {
    id: string;
  };
}

interface NewShopFormValues {
  apiKey: string;
  password: string;
  domain: string;
}

const NewShopifyConnectionForm = () => {
  const connectShopify = useConnectShopifyMutation();

  const onSubmit = React.useCallback(
    async (formValues: NewShopFormValues, setShow: (modalShow: boolean) => void) => {
      let success = false;
      let result;
      try {
        result = await connectShopify({ variables: formValues, refetchQueries: [{ query: GetConnectionsIndexPageDocument }] });
      } catch (e) {}

      const data = mutationSuccess(result, "connectShopify");
      if (data) {
        success = true;
        toast.success("Shopify connected successfully.");
      }

      if (!success) {
        toast.error("There was an error connecting Shopify. Please try again.");
      } else {
        setShow(false);
      }
    },
    [connectShopify]
  );

  return (
    <SimpleModal triggerLabel="Connect Shopify" triggerIcon={<Add />}>
      {setShow => (
        <SuperForm<NewShopFormValues> onSubmit={doc => onSubmit(doc, setShow)} initialValues={{ apiKey: "", password: "", domain: "" }}>
          {form => (
            <Box height="medium" width="medium">
              <Heading level="3">Connect New Shopify Shop</Heading>
              <Tabs>
                <Tab title="Standard App">
                  <Box align="center">
                    <p>Visit Shopify to give Superpro permission to access your store.</p>
                    <FieldBox path="domain" label="Shopify Shop domain">
                      <Input path="domain" />
                    </FieldBox>
                    <Button
                      icon={<Add />}
                      label="Connect Shopify"
                      href={`/connection_auth/shopify?shop=${encodeURIComponent(form.doc.domain)}`}
                    />
                  </Box>
                </Tab>
                <Tab title="Private App">
                  <Box gap="small">
                    <FieldBox path="domain" label="Shopify Shop domain">
                      <Input path="domain" />
                    </FieldBox>
                    <FieldBox path="apiKey" label="API Key">
                      <Input path="apiKey" />
                    </FieldBox>
                    <FieldBox path="password" label="API Password">
                      <Input path="password" />
                    </FieldBox>
                    <Button type="submit" label="Connect" />
                  </Box>
                </Tab>
              </Tabs>
            </Box>
          )}
        </SuperForm>
      )}
    </SimpleModal>
  );
};

export const ShopifyConnectionCard = () => {
  return (
    <ConnectionCard
      name="Shopify"
      description="Superpro connects to [Shopify](https://www.shopify.com/) to import your order, inventory, customer, and web traffic data."
    >
      <NewShopifyConnectionForm />
    </ConnectionCard>
  );
};
