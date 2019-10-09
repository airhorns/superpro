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
  GetConnectionsIndexPageDocument,
  useDiscardConnectionMutation
} from "app/app-graph";
import { Restart, Trash, CloudGo, Pause, Play } from "app/components/common/SuperproIcons";
import { ConnectionGlyph } from "./ConnectionGlyph";

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

  mutation DiscardConnection($connectionId: ID!) {
    discardConnection(connectionId: $connectionId) {
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
  const restartConnectionSync = useRestartConnectionSyncMutation()[0];
  const syncConnectionNow = useSyncConnectionNowMutation()[0];
  const setConnectionEnabled = useSetConnectionEnabledMutation()[0];
  const discardConnection = useDiscardConnectionMutation()[0];

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

  const onDiscardClick = React.useCallback(async () => {
    let result;
    try {
      result = await discardConnection({
        variables: { connectionId: props.connection.id },
        refetchQueries: [{ query: GetConnectionsIndexPageDocument }]
      });
      const data = mutationSuccess(result, "discardConnection");
      if (data) {
        return toast.success("Connection deleted successfully.");
      }
    } catch (e) {}
    toast.error("There was an error deleting this connection.");
  }, [props.connection.id, discardConnection]);

  return (
    <Row pad="small" gap="small" key={props.connection.id}>
      <ConnectionGlyph typename={props.connection.integration.__typename} />
      <Box flex={{ grow: 1 }}>
        <Heading level="3">{props.connection.displayName}</Heading>
        <Row justify="between">
          <ConnectionEnabledIndicator enabled={props.connection.enabled} />
          <ConnectionSyncDiagram syncAttempts={props.connection.syncAttempts.nodes} />
          <Menu
            label="Actions"
            items={[
              {
                icon: (
                  <Box margin={{ right: "small" }}>
                    <CloudGo />
                  </Box>
                ),
                label: "Sync Now",
                onClick: onSyncClick
              },
              {
                icon: (
                  <Box margin={{ right: "small" }}>
                    <Restart />
                  </Box>
                ),
                label: "Restart Sync",
                onClick: onRestartClick
              },
              {
                icon: <Box margin={{ right: "small" }}>{props.connection.enabled ? <Pause /> : <Play />}</Box>,
                label: props.connection.enabled ? "Pause" : "Resume",
                onClick: () => onToggleEnabled(!props.connection.enabled)
              },
              {
                icon: (
                  <Box margin={{ right: "small" }}>
                    <Trash />
                  </Box>
                ),
                label: "Delete",
                onClick: onDiscardClick
              }
            ]}
          />
        </Row>
      </Box>
    </Row>
  );
};
