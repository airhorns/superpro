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
  Underline as GrommetUnderline,
  BlockQuote as GrommetBlockQuote,
  Superscript,
  CircleQuestion,
  Edit as GrommetEdit,
  Add as GrommetAdd,
  FormClose as GrommetFormClose,
  Link as GrommetLink,
  Previous as GrommetPrevious,
  Launch,
  Compare,
  Menu,
  Analytics,
  Code as GrommetCode,
  List,
  OrderedList as GrommetOrderedList,
  Task,
  Currency,
  Alarm,
  UserAdd,
  Share as GrommetShare,
  Configure,
  Image as GrommetImage,
  Cycle,
  CirclePlay,
  Pause as GrommetPause,
  CloudDownload
} from "grommet-icons";

// Navigation & Root level ideas
export const SuperproLogo = Launch;
export const Home = GrommetHome;
export const Reports = Analytics;
export const Invite = UserAdd;
export const Settings = Configure;

// Toolbar & Editor
export const Undo = GrommetUndo;
export const Redo = GrommetRedo;
export const Trash = GrommetTrash;
export const Refresh = GrommetRefresh;
export const Preview = GrommetView;
export const Bold = GrommetBold;
export const Italic = GrommetItalic;
export const Underline = GrommetUnderline;
export const Code = GrommetCode;
export const BlockQuote = GrommetBlockQuote;
export const FontSize = Superscript;
export const BulletedList = List;
export const OrderedList = GrommetOrderedList;
export const Image = GrommetImage;
export const CheckList = Task;
export const Link = GrommetLink;
export const Expense = Currency;
export const Deadline = Alarm;
export const Share = GrommetShare;

// Misc
export const Previous = GrommetPrevious;
export const Question = CircleQuestion;
export const Edit = GrommetEdit;
export const Add = GrommetAdd;
export const FormClose = GrommetFormClose;
export const DragHandle = Menu;
export const Restart = Cycle;
export const Play = CirclePlay;
export const Pause = GrommetPause;
export const CloudGo = CloudDownload;
export const Test = Compare;

export const AddStack = (props: { icon: React.ReactNode; anchor?: StackProps["anchor"] }) => (
  <Stack anchor={props.anchor || "bottom-right"}>
    {props.icon}
    <Box background="brand" pad="2px" round>
      <Add size="small" />
    </Box>
  </Stack>
);
