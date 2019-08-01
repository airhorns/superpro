import React from "react";
import gql from "graphql-tag";
import { ConnectionCard } from "./ConnectionCard";
import { useConnectShopifyMutation, GetConnectionsIndexPageDocument } from "app/app-graph";
import { mutationSuccess, toast, SimpleModal, Row } from "superlib";
import { Box, Text, Heading, Button } from "grommet";
import { Add } from "app/components/common/SuperproIcons";
import { Input, FieldBox, SuperForm } from "superlib/superform";
import { RestartConnectionSyncButton } from "./RestartConnectionSyncButton";

gql`
  fragment ShopifyConnectionCardContent on ShopifyShop {
    id
    name
    shopifyDomain
    shopId
    connection {
      id
    }
  }

  mutation ConnectShopify($apiKey: String!, $password: String!, $domain: String!) {
    connectShopify(apiKey: $apiKey, password: $password, domain: $domain) {
      errors
      shopifyShop {
        ...ShopifyConnectionCardContent
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
          {() => (
            <Box gap="small">
              <Heading level="3">Connect New Shopify Shop</Heading>
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
      )}
    </SimpleModal>
  );
};

export const ShopifyConnectionCard = (props: { shopifyShops: ShopifyShop[] }) => {
  return (
    <ConnectionCard
      name="Shopify"
      description="Superpro connects to [Shopify](https://www.shopify.com/) to import your order, inventory, customer, and web traffic data."
    >
      {props.shopifyShops.length > 0 && (
        <Box>
          <Text>Currently Connected Shops:</Text>
          <ul>
            {props.shopifyShops.map(shop => (
              <li key={shop.id}>
                <Box gap="small">
                  <Heading level="5">{shop.name}</Heading>
                  <Row justify="between">
                    <a href={`https://${shop.shopifyDomain}`}>{shop.shopifyDomain}</a>
                    <RestartConnectionSyncButton connection={shop.connection} />
                  </Row>
                </Box>
              </li>
            ))}
          </ul>
        </Box>
      )}
      <NewShopifyConnectionForm />
    </ConnectionCard>
  );
};
