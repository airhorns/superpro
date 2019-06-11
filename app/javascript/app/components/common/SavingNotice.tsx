import React from "react";
import { Box, Text } from "grommet";

export const SavingNotice = (props: { lastChangeAt: Date | null; lastSaveAt: Date | null }) => {
  let content: string;

  if (!props.lastChangeAt) {
    content = "No changes made.";
  } else if (!props.lastSaveAt || props.lastSaveAt < props.lastChangeAt) {
    content = "Saving ...";
  } else {
    content = "All changes saved.";
  }

  return (
    <Box margin={{ right: "small" }} justify="center">
      <Text color="light-5">{content}</Text>
    </Box>
  );
};
