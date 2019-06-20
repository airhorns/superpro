import React from "react";
import Automerge from "automerge";
import { useSuperForm } from "flurishlib/superform";
import { Button } from "grommet";
import { Row } from "flurishlib";
import { BudgetFormValues } from "./BudgetForm";
import { Undo, Redo } from "../common/FlurishIcons";
import { BudgetFormNewSectionModal } from "./BudgetFormNewSectionList";

export const BudgetFormToolbar = (_props: {}) => {
  const form = useSuperForm<BudgetFormValues>();
  const history = Automerge.getHistory(form.doc);
  const changes = Automerge.diff(history[0].snapshot, form.doc);
  console.log(changes);
  return (
    <Row pad={{ horizontal: "small" }}>
      <BudgetFormNewSectionModal />
      <Button icon={<Undo />} disabled={!form.canUndo()} onClick={() => form.undo()} />
      <Button icon={<Redo />} disabled={!form.canRedo()} onClick={() => form.redo()} />
    </Row>
  );
};
