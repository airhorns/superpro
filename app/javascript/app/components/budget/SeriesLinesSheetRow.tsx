import React from "react";
import { Draggable } from "react-beautiful-dnd";
import { isTouchDevice, Row } from "superlib";
import { useSuperForm } from "superlib/superform";
import { FadeBox, TrashButton, ScenarioButton } from "app/components/common";
import { DragHandle } from "app/components/common/SuperproIcons";
import { BudgetFormValues, BudgetFormLine } from "./BudgetForm";
import {
  TextSheetCell,
  NumberSheetCell,
  StyledDataGridRow,
  StaticSheetCell,
  StyledDataGridFakeCell,
  StyledDataGridCell
} from "superlib/supersheet";
import { DefaultCellMonths } from "./SeriesLinesSheet";
import { Button } from "grommet";

export const SeriesLineSheetRow = (props: { line: BudgetFormLine; rowIndex: number; linesIndex: number }) => {
  const form = useSuperForm<BudgetFormValues>();
  const [hovered, setHovered] = React.useState(false);
  const showIcons = isTouchDevice() || hovered;
  const lineFieldKey = `budget.lines.${props.linesIndex}`;
  const lineHelpers = form.arrayHelpers("budget.lines");
  const scenariosEnabledKey = `${lineFieldKey}.value.scenariosEnabled`;
  const scenariosEnabled = form.getValue(scenariosEnabledKey);

  const toggleScenarios = React.useCallback(() => {
    const enabled = form.getValue(scenariosEnabledKey);
    if (enabled) {
      form.setValue(scenariosEnabledKey, false);
    } else {
      form.setValue(scenariosEnabledKey, true);
    }
  }, [form, scenariosEnabledKey]);

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
          <StaticSheetCell key="draghandle" width="96px">
            <FadeBox visible={showIcons}>
              <Row gap="xsmall">
                <DragHandle color="light-5" />
                <Button
                  hoverIndicator
                  plain={false}
                  icon={<ScenarioButton enabled={false} />}
                  style={{ padding: "7px" }}
                  onClick={toggleScenarios}
                />
                <TrashButton size="small" onClick={() => lineHelpers.deleteAt(props.linesIndex)} />
              </Row>
            </FadeBox>
          </StaticSheetCell>
          <TextSheetCell
            row={props.rowIndex}
            width="244px"
            column={0}
            rowSpan={scenariosEnabled ? 3 : 1}
            path={`${lineFieldKey}.description`}
            placeholder="Line description"
          />
          {DefaultCellMonths().map((dateTime, index) => {
            const cellProps = {
              prefix: "$",
              fixedDecimalScale: true,
              decimalScale: 2,
              storeAsSubunits: true
            };
            if (scenariosEnabled) {
              return (
                <StyledDataGridCell width="96px">
                  {["optimistic", "default", "pessimistic"].map((scenario, scenarioIndex) => (
                    <NumberSheetCell
                      width="96px"
                      row={props.rowIndex + scenarioIndex}
                      column={index + 1}
                      key={scenario}
                      path={`${lineFieldKey}.value.cells.${dateTime.valueOf()}.amountScenarios.${scenario}`}
                      as={StyledDataGridFakeCell}
                      {...cellProps}
                    />
                  ))}
                </StyledDataGridCell>
              );
            } else {
              return (
                <NumberSheetCell
                  width="96px"
                  row={props.rowIndex}
                  column={index + 1}
                  path={`${lineFieldKey}.value.cells.${dateTime.valueOf()}.amountScenarios.default`}
                  {...cellProps}
                />
              );
            }
          })}
        </StyledDataGridRow>
      )}
    </Draggable>
  );
};
