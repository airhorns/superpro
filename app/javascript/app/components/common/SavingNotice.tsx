import React from "react";
import { Box, Text, ResponsiveContext } from "grommet";

const noticePositionForScreenSize = (size: string): React.CSSProperties | undefined => {
  if (size == "small") {
    return { position: "fixed", right: "0", bottom: "0" };
  }
};

export interface SavingNoticeState {
  lastSaveAt: null | Date;
  lastChangeAt: null | Date;
}

export const SavingNotice = (props: { lastChangeAt: Date | null; lastSaveAt: Date | null }) => {
  const size = React.useContext(ResponsiveContext);
  let content: string;

  if (!props.lastChangeAt) {
    content = "No changes made.";
  } else if (!props.lastSaveAt || props.lastSaveAt < props.lastChangeAt) {
    content = "Saving ...";
  } else {
    content = "All changes saved.";
  }

  return (
    <Box margin={{ right: "small" }} justify="center" style={noticePositionForScreenSize(size)}>
      <Text color="light-5">{content}</Text>
    </Box>
  );
};
