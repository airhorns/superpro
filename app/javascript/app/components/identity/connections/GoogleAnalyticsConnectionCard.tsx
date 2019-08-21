import React from "react";
import gql from "graphql-tag";
import { ConnectionCard } from "./ConnectionCard";
import { mutationSuccess, toast, SimpleModal, Row } from "superlib";
import { Box, Text, Heading, Button, Anchor } from "grommet";
import { Add } from "app/components/common/SuperproIcons";
import { Input, FieldBox, SuperForm } from "superlib/superform";
import { RestartConnectionSyncButton } from "./RestartConnectionSyncButton";

// gql``;

// interface GoogleAnalyticsShop {
//   id: string;
//   name: string;
//   GoogleAnalyticsDomain: string;
//   shopId: string;
//   connection: {
//     id: string;
//   };
// }

// interface NewShopFormValues {
//   apiKey: string;
//   password: string;
//   domain: string;
// }

// const NewGoogleAnalyticsConnectionForm = () => {
//   const connectGoogleAnalytics = useConnectGoogleAnalyticsMutation();

//   const onSubmit = React.useCallback(
//     async (formValues: NewShopFormValues, setShow: (modalShow: boolean) => void) => {
//       let success = false;
//       let result;
//       try {
//         result = await connectGoogleAnalytics({ variables: formValues, refetchQueries: [{ query: GetConnectionsIndexPageDocument }] });
//       } catch (e) {}

//       const data = mutationSuccess(result, "connectGoogleAnalytics");
//       if (data) {
//         success = true;
//         toast.success("GoogleAnalytics connected successfully.");
//       }

//       if (!success) {
//         toast.error("There was an error connecting GoogleAnalytics. Please try again.");
//       } else {
//         setShow(false);
//       }
//     },
//     [connectGoogleAnalytics]
//   );

//   return (
//     <SimpleModal triggerLabel="Connect GoogleAnalytics" triggerIcon={<Add />}>
//       {setShow => (
//         <SuperForm<NewShopFormValues> onSubmit={doc => onSubmit(doc, setShow)} initialValues={{ apiKey: "", password: "", domain: "" }}>
//           {() => (
//             <Box gap="small">
//               <Heading level="3">Connect New GoogleAnalytics Shop</Heading>
//               <FieldBox path="domain" label="GoogleAnalytics Shop domain">
//                 <Input path="domain" />
//               </FieldBox>
//               <FieldBox path="apiKey" label="API Key">
//                 <Input path="apiKey" />
//               </FieldBox>
//               <FieldBox path="password" label="API Password">
//                 <Input path="password" />
//               </FieldBox>
//               <Button type="submit" label="Connect" />
//             </Box>
//           )}
//         </SuperForm>
//       )}
//     </SimpleModal>
//   );
// };

export const GoogleAnalyticsConnectionCard = (_props: {}) => {
  return (
    <ConnectionCard
      name="Google Analytics"
      description="Superpro connects to [Google Analytics](https://analytics.google.com/) to import your order, inventory, customer, and web traffic data."
    >
      <Anchor href="/connauth/auth/google_oauth2">Connect Google Analytics</Anchor>
    </ConnectionCard>
  );
};
