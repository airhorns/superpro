import React from "react";
import { useSuperForm } from "flurishlib/superform";
import { Button } from "grommet";
import { Row, Hotkey, Hotkeys } from "flurishlib";
import { BudgetFormValues } from "./BudgetForm";
import { Undo, Redo } from "../common/FlurishIcons";
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
