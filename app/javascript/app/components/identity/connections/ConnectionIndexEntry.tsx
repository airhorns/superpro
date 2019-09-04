import React from "react";
import gql from "graphql-tag";
import { Box, Heading, Menu } from "grommet";
import { Row, mutationSuccess, toast } from "superlib";
import { ConnectionSyncDiagram } from "./ConnectionSyncDiagram";
import {
  ConnectionIndexEntryFragment,
  useRestartConnectionSyncMutation,
  useSyncConnectionNowMutation,
  useSetConnectionEnabledMutation,
  GetConnectionsIndexPageDocument
} from "app/app-graph";
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
        startedAt
        finishedAt
        failureReason
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

  mutation SyncConnectionNow($connectionId: ID!) {
    syncConnectionNow(connectionId: $connectionId) {
      connection {
        id
      }
      errors
    }
  }

  mutation SetConnectionEnabled($connectionId: ID!, $enabled: Boolean!) {
    setConnectionEnabled(connectionId: $connectionId, enabled: $enabled) {
      connection {
        id
        enabled
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
  const syncConnectionNow = useSyncConnectionNowMutation();
  const setConnectionEnabled = useSetConnectionEnabledMutation();

  const onRestartClick = React.useCallback(async () => {
    let result;
    try {
      result = await restartConnectionSync({
        variables: { connectionId: props.connection.id },
        refetchQueries: [{ query: GetConnectionsIndexPageDocument }]
      });
      const data = mutationSuccess(result, "restartConnectionSync");
      if (data) {
        return toast.success("Connection sync restarted successfully.");
      }
    } catch (e) {}
    toast.error("There was an error restarting this connection sync.");
  }, [props.connection.id, restartConnectionSync]);

  const onSyncClick = React.useCallback(async () => {
    let result;
    try {
      result = await syncConnectionNow({ variables: { connectionId: props.connection.id } });
      const data = mutationSuccess(result, "syncConnectionNow");
      if (data) {
        return toast.success("Connection sync started successfully.");
      }
    } catch (e) {}
    toast.error("There was an error starting this connection sync.");
  }, [props.connection.id, syncConnectionNow]);

  const onToggleEnabled = React.useCallback(
    async (enabled: boolean) => {
      let result;
      try {
        result = await setConnectionEnabled({
          variables: { connectionId: props.connection.id, enabled: enabled },
          refetchQueries: [{ query: GetConnectionsIndexPageDocument }]
        });
        const data = mutationSuccess(result, "setConnectionEnabled");
        if (data) {
          return toast.success(`Connection ${enabled ? "enabled" : "disabled"} successfully.`);
        }
      } catch (e) {}
      toast.error(`There was an error ${enabled ? "enabling" : "disabling"} this connection sync.`);
    },
    [props.connection.id, setConnectionEnabled]
  );

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
            { icon: <CloudGo />, label: "Sync Now", onClick: onSyncClick },
            { icon: <Restart />, label: "Restart Sync", onClick: onRestartClick },
            {
              icon: props.connection.enabled ? <Pause /> : <Play />,
              label: props.connection.enabled ? "Pause" : "Resume",
              onClick: () => onToggleEnabled(!props.connection.enabled)
            },
            { icon: <Trash />, label: "Delete" }
          ]}
        />
      </Row>
    </Box>
  );
};
