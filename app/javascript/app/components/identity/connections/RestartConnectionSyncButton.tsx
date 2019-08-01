import React from "react";
import gql from "graphql-tag";
import { Button } from "grommet";
import { Restart } from "app/components/common/SuperproIcons";
import { useRestartConnectionSyncMutation } from "app/app-graph";
import { mutationSuccess, toast } from "superlib";

gql`
  mutation RestartConnectionSync($connectionId: ID!) {
    restartConnectionSync(connectionId: $connectionId) {
      connection {
        id
      }
      errors
    }
  }
`;

export const RestartConnectionSyncButton = (props: { connection: { id: string } }) => {
  const restartConnectionSync = useRestartConnectionSyncMutation();
  const onClick = React.useCallback(async () => {
    let result;
    try {
      result = await restartConnectionSync({ variables: { connectionId: props.connection.id } });
      const data = mutationSuccess(result, "restartConnectionSync");
      if (data) {
        return toast.success("Connection sync restarted successfully.");
      }
    } catch (e) {}
    toast.error("There was an error restarting this connection sync.");
  }, [props.connection.id, restartConnectionSync]);

  return <Button icon={<Restart />} onClick={onClick} />;
};
