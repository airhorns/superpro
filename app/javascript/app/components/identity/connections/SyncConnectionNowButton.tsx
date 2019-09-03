import React from "react";
import gql from "graphql-tag";
import { Button } from "grommet";
import { Go } from "app/components/common/SuperproIcons";
// import { useSyncConnectionNowMutation } from "app/app-graph";
import { mutationSuccess, toast } from "superlib";

// gql`
//   mutation SyncConnectionNow($connectionId: ID!) {
//     SyncConnectionNow(connectionId: $connectionId) {
//       connection {
//         id
//       }
//       errors
//     }
//   }
// `;

export const SyncConnectionNowButton = (props: { connection: { id: string } }) => {
  // const SyncConnectionNow = useSyncConnectionNowMutation();
  // const onClick = React.useCallback(async () => {
  //   let result;
  //   try {
  //     result = await SyncConnectionNow({ variables: { connectionId: props.connection.id } });
  //     const data = mutationSuccess(result, "SyncConnectionNow");
  //     if (data) {
  //       return toast.success("Connection sync restarted successfully.");
  //     }
  //   } catch (e) {}
  //   toast.error("There was an error restarting this connection sync.");
  // }, [props.connection.id, SyncConnectionNow])

  return <Button icon={<Go />} onClick={() => {}} />;
};
