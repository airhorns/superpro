import React from "react";
import { Box, Stack, StackProps } from "grommet";
import {
  Home as GrommetHome,
  Undo as GrommetUndo,
  Redo as GrommetRedo,
  Trash as GrommetTrash,
  Refresh as GrommetRefresh,
  View as GrommetView,
  Bold as GrommetBold,
  Italic as GrommetItalic,
  Tape,
  Superscript,
  CircleQuestion,
  Edit as GrommetEdit,
  Add as GrommetAdd,
  FormClose as GrommetFormClose,
  Link as GrommetLink,
  Previous as GrommetPrevious,
  Launch
} from "grommet-icons";

// Navigation & Root level ideas
export const FlurishLogo = Launch;
export const Home = GrommetHome;

// Toolbar & Editor
export const Undo = GrommetUndo;
export const Redo = GrommetRedo;
export const Trash = GrommetTrash;
export const Refresh = GrommetRefresh;
export const Preview = GrommetView;
export const Bold = GrommetBold;
export const Italic = GrommetItalic;
export const Token = Tape;
export const FontSize = Superscript;
export const Link = GrommetLink;

// Misc
export const Previous = GrommetPrevious;
export const Question = CircleQuestion;
export const Edit = GrommetEdit;
export const Add = GrommetAdd;
export const FormClose = GrommetFormClose;

export const AddStack = (props: { icon: React.ReactNode; anchor?: StackProps["anchor"] }) => (
  <Stack anchor={props.anchor || "bottom-right"}>
    {props.icon}
    <Box background="brand" pad="2px" round>
      <Add size="small" />
    </Box>
  </Stack>
);
