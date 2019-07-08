import React from "react";
import { useSuperForm } from "superlib/superform";
import { Button } from "grommet";
import { Row, Hotkey, Hotkeys } from "superlib";
import { BudgetFormValues } from "./BudgetForm";
import { Undo, Redo } from "../common/SuperproIcons";
import { BudgetFormNewSectionModal } from "./BudgetFormNewSectionList";

export const BudgetFormToolbar = (_props: {}) => {
  const form = useSuperForm<BudgetFormValues>();

  return (
    <Row pad={{ horizontal: "small" }}>
      <BudgetFormNewSectionModal />
      <Button icon={<Undo />} disabled={!form.canUndo()} onClick={() => form.undo()} />
      <Hotkey detector={Hotkeys.isUndo} onHotkey={() => form.canUndo() && form.undo()} />
      <Button icon={<Redo />} disabled={!form.canRedo()} onClick={() => form.redo()} />
      <Hotkey detector={Hotkeys.isRedo} onHotkey={() => form.canRedo() && form.redo()} />
    </Row>
  );
};
