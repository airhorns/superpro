import React from "react";
import gql from "graphql-tag";
import { Box, Heading, Menu } from "grommet";
import { Row, mutationSuccess, toast } from "superlib";
import { ConnectionSyncDiagram } from "./ConnectionSyncDiagram";
import { ConnectionIndexEntryFragment, useRestartConnectionSyncMutation } from "app/app-graph";
import { Restart, Trash, CloudGo, Test, Pause, Play } from "app/components/common/SuperproIcons";

gql`
  fragment ConnectionIndexEntry on Connectionobj {
    id
    displayName
    integration {
      __typename
      ... on ShopifyShop {
        id
        name
        shopifyDomain
        shopId
      }
    }
    supportsSync
    syncAttempts(first: 15) {
      nodes {
        id
        success
        finishedAt
      }
    }
    enabled
  }

  mutation RestartConnectionSync($connectionId: ID!) {
    restartConnectionSync(connectionId: $connectionId) {
      connection {
        id
      }
      errors
    }
  }
`;

const ConnectionEnabledIndicator = (props: { enabled: boolean }) => {
  const text = props.enabled ? "Enabled" : "Paused";
  const icon = props.enabled ? <Play /> : <Pause />;
  return (
    <Row border="all" gap="small" pad={{ horizontal: "medium", vertical: "xsmall" }} round>
      {icon}
      {text}
    </Row>
  );
};

export const ConnectionIndexEntry = (props: { connection: ConnectionIndexEntryFragment }) => {
  const restartConnectionSync = useRestartConnectionSyncMutation();
  const onRestartClick = React.useCallback(async () => {
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

  return (
    <Box pad="small" key={props.connection.id}>
      <Heading level="3">{props.connection.displayName}</Heading>
      <Row justify="between">
        <ConnectionEnabledIndicator enabled={props.connection.enabled} />
        <ConnectionSyncDiagram syncAttempts={props.connection.syncAttempts.nodes} />
        <Menu
          label="Actions"
          items={[
            { icon: <Test />, label: "Test Connection" },
            { icon: <CloudGo />, label: "Sync Now" },
            { icon: <Restart />, label: "Restart Sync", onClick: onRestartClick },
            { icon: <Pause />, label: "Pause" },
            { icon: <Trash />, label: "Delete" }
          ]}
        />
      </Row>
    </Box>
  );
};
