import React from "react";
import gql from "graphql-tag";
import { ConnectionCard } from "./ConnectionCard";
import { useConnectShopifyMutation, GetConnectionsIndexPageDocument } from "app/app-graph";
import { mutationSuccess, toast, SimpleModal } from "superlib";
import { Box, Heading, Button, Tabs, Tab, Text } from "grommet";
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

interface NewPrivateAppShopFormValues {
  apiKey: string;
  password: string;
  domain: string;
}

const NewShopifyConnectionForm = () => {
  const connectShopify = useConnectShopifyMutation()[0];

  const onSubmit = React.useCallback(
    async (formValues: NewPrivateAppShopFormValues, setShow: (modalShow: boolean) => void) => {
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
        <Box width="medium" gap="small">
          <Heading level="3">Connect New Shopify Shop</Heading>
          <Tabs>
            <Tab title="Standard App">
              <SuperForm<{ domain: string }>
                onSubmit={doc => (window.location.href = `/connection_auth/shopify?shop=${encodeURIComponent(doc.domain)}`)}
                initialValues={{ domain: "" }}
              >
                {() => (
                  <Box align="center">
                    <p>Visit Shopify to give Superpro permission to access your store.</p>
                    <FieldBox path="domain" label="Shopify Shop domain">
                      <Input path="domain" />
                    </FieldBox>
                    <Text color="status-disabled">
                      Please enter your <code>something.myshopify.com</code> domain to begin the process, including the&nbsp;
                      <code>myshopify.com</code>&nbsp; part.
                    </Text>
                    <Box pad="small" margin={{ top: "medium" }}>
                      <Button icon={<Add />} label="Connect Shopify" type="submit" />
                    </Box>
                  </Box>
                )}
              </SuperForm>
            </Tab>
            <Tab title="Private App">
              <SuperForm<NewPrivateAppShopFormValues>
                onSubmit={doc => onSubmit(doc, setShow)}
                initialValues={{ apiKey: "", password: "", domain: "" }}
              >
                {() => (
                  <Box gap="small">
                    <p>If you&quot;ve been instructed to use a Private App from Shopify to connect Superpro, add its details here.</p>
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
                )}
              </SuperForm>
            </Tab>
          </Tabs>
        </Box>
      )}
    </SimpleModal>
  );
};

export const ShopifyConnectionCard = () => {
  return (
    <ConnectionCard
      name="Shopify"
      description="Superpro connects to [Shopify](https://www.shopify.com/) to import your order, inventory, customer, and web traffic data."
      typename="ShopifyShop"
    >
      <NewShopifyConnectionForm />
    </ConnectionCard>
  );
};
