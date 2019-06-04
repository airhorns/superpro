import React from "react";
import { Box, Text } from "grommet";
import { Alert as AlertIcon, Notification as NotificationIcon } from "grommet-icons";

export const Alert = (props: { type: "error" | "warning" | "info" | "success"; message: React.ReactNode }) => {
  let color: string;
  if (props.type == "error") {
    color = "status-critical";
  } else if (props.type == "warning") {
    color = "status-warning";
  } else if (props.type == "success") {
    color = "status-ok";
  } else {
    color = "dark-1";
  }

  return (
    <Box justify="center" align="center" pad="medium" round={true} margin="small">
      <Text color={color} size="large">
        {props.type == "error" ? <AlertIcon /> : <NotificationIcon />}
      </Text>
      <Text color={color}>{props.message}</Text>
    </Box>
  );
};
