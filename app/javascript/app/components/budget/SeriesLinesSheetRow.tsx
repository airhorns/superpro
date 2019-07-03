import React from "react";
import { Text } from "grommet";
import { Draggable } from "react-beautiful-dnd";
import { isTouchDevice } from "flurishlib";
import { Input, NumberInput, useSuperForm } from "flurishlib/superform";
import { FadeBox, TrashButton } from "app/components/common";
import { DragHandle } from "app/components/common/FlurishIcons";
import { BudgetFormValues, BudgetFormLine } from "./BudgetForm";
import { StyledDataGridRow, StyledDataGridCell } from "./sheet/StyledDataGrid";
import { DefaultCellMonths } from "./SeriesLinesSheet";
import { SheetCell } from "./sheet/SheetCell";

export const SheetRow = (props: { line: BudgetFormLine; rowIndex: number; linesIndex: number }) => {
  const form = useSuperForm<BudgetFormValues>();
  const [hovered, setHovered] = React.useState(false);
  const showIcons = isTouchDevice() || hovered;
  const lineFieldKey = `budget.lines.${props.linesIndex}`;
  const lineHelpers = form.arrayHelpers("budget.lines");

  return (
    <Draggable draggableId={props.line.id} index={props.line.sortOrder}>
      {provided => (
        <StyledDataGridRow
          onMouseEnter={() => setHovered(true)}
          onMouseLeave={() => setHovered(false)}
          ref={provided.innerRef as any}
          {...provided.draggableProps}
          {...provided.dragHandleProps}
        >
          <StyledDataGridCell key="draghandle">
            <FadeBox visible={showIcons}>
              <DragHandle color="light-5" />
            </FadeBox>
          </StyledDataGridCell>
          <SheetCell row={props.rowIndex} column={0} key="name">
            {({ editing, inputProps }) => {
              const path = `${lineFieldKey}.description`;
              const value = form.getValue(path);
              if (editing) {
                return <Input autoFocus path={path} placeholder="Line description" plain {...inputProps} />;
              } else {
                if (value) {
                  return <Text>{form.getValue(path)}</Text>;
                } else {
                  return <Text color="status-unknown">Line description</Text>;
                }
              }
            }}
          </SheetCell>
          {DefaultCellMonths().map((dateTime, index) => (
            <SheetCell row={props.rowIndex} column={index + 1} key={index}>
              {({ editing, inputProps }) => (
                <NumberInput
                  plain
                  autoFocus
                  path={`${lineFieldKey}.value.cells.${dateTime.valueOf()}.amountScenarios.default`}
                  prefix={"$"}
                  fixedDecimalScale
                  decimalScale={2}
                  storeAsSubunits
                  style={{ padding: "0px" }}
                  displayType={editing ? "input" : "text"}
                  {...inputProps}
                />
              )}
            </SheetCell>
          ))}
          <StyledDataGridCell key="actions">
            <FadeBox visible={showIcons}>
              <TrashButton size="small" onClick={() => lineHelpers.deleteAt(props.linesIndex)} />
            </FadeBox>
          </StyledDataGridCell>
        </StyledDataGridRow>
      )}
    </Draggable>
  );
};
