import React from "react";
import { Draggable } from "react-beautiful-dnd";
import { isTouchDevice } from "superlib";
import { useSuperForm } from "superlib/superform";
import { FadeBox, TrashButton } from "app/components/common";
import { DragHandle } from "app/components/common/SuperproIcons";
import { BudgetFormValues, BudgetFormLine } from "./BudgetForm";
import { TextSheetCell, NumberSheetCell, StyledDataGridRow, StaticSheetCell } from "superlib/supersheet";
import { DefaultCellMonths } from "./SeriesLinesSheet";

export const SeriesLineSheetRow = (props: { line: BudgetFormLine; rowIndex: number; linesIndex: number }) => {
  const form = useSuperForm<BudgetFormValues>();
  const [hovered, setHovered] = React.useState(false);
  const showIcons = isTouchDevice() || hovered;
  const lineFieldKey = `budget.lines.${props.linesIndex}`;
  const lineHelpers = form.arrayHelpers("budget.lines");

  return (
    <Draggable draggableId={props.line.id} index={props.line.sortOrder}>
      {(provided, snapshot) => (
        <StyledDataGridRow
          dragging={snapshot.isDragging}
          onMouseEnter={() => setHovered(true)}
          onMouseLeave={() => setHovered(false)}
          ref={provided.innerRef as any}
          {...provided.draggableProps}
          {...provided.dragHandleProps}
        >
          <StaticSheetCell key="draghandle">
            <FadeBox visible={showIcons}>
              <DragHandle color="light-5" />
            </FadeBox>
          </StaticSheetCell>
          <TextSheetCell row={props.rowIndex} column={0} path={`${lineFieldKey}.description`} placeholder="Line description" />
          {DefaultCellMonths().map((dateTime, index) => (
            <NumberSheetCell
              row={props.rowIndex}
              column={index + 1}
              key={index}
              path={`${lineFieldKey}.value.cells.${dateTime.valueOf()}.amountScenarios.default`}
              prefix={"$"}
              fixedDecimalScale
              decimalScale={2}
              storeAsSubunits
            />
          ))}
          <StaticSheetCell key="actions">
            <FadeBox visible={showIcons}>
              <TrashButton size="small" onClick={() => lineHelpers.deleteAt(props.linesIndex)} />
            </FadeBox>
          </StaticSheetCell>
        </StyledDataGridRow>
      )}
    </Draggable>
  );
};
