import React from "react";
import { Draggable } from "react-beautiful-dnd";
import { TrashButton, FadeBox } from "../common";
import { Box } from "grommet";
import { Row, shallowSubsetEqual, shallowEqual, isTouchDevice } from "flurishlib";
import { BudgetFormLineValue, BudgetFormValues } from "./BudgetForm";
import { DragHandle } from "../common/FlurishIcons";
import { SuperForm, Input, Select, NumberInput } from "flurishlib/superform";

export interface BudgetLineFormProps {
  linesIndex: number;
  line: BudgetFormLineValue;
  form: SuperForm<BudgetFormValues>;
}

export interface BudgetLineFormState {
  hovered: boolean;
}

export class BudgetLineForm extends React.Component<BudgetLineFormProps, BudgetLineFormState> {
  state: BudgetLineFormState = { hovered: false };

  shouldComponentUpdate(nextProps: BudgetLineFormProps, nextState: BudgetLineFormState) {
    return !shallowEqual(this.state, nextState) || !shallowSubsetEqual(["line", "sectionIndex", "lineFieldKey"], this.props, nextProps);
  }

  render() {
    const showIcons = isTouchDevice() || this.state.hovered;
    const lineFieldKey = `budget.lines.${this.props.linesIndex}`;
    const lineHelpers = this.props.form.arrayHelpers(lineFieldKey);

    return (
      <Draggable draggableId={this.props.line.id} index={this.props.line.sortOrder}>
        {provided => (
          <Row
            pad="small"
            gap="medium"
            wrap
            ref={provided.innerRef as any}
            {...provided.draggableProps}
            {...provided.dragHandleProps}
            onMouseEnter={() => this.setState({ hovered: true })}
            onMouseLeave={() => this.setState({ hovered: false })}
          >
            <Box>
              <FadeBox visible={showIcons}>
                <DragHandle color="light-5" />
              </FadeBox>
            </Box>
            <Box width="medium">
              <Input path={`${lineFieldKey}.description`} placeholder="Line description" />
            </Box>
            <Box width="small">
              <Select path={`${lineFieldKey}.variable`} options={[{ value: true, label: "Variable" }, { value: false, label: "Fixed" }]} />
            </Box>
            <Box width="small">
              <Select
                path={`${lineFieldKey}.frequency`}
                options={[
                  { value: "daily", label: "Daily" },
                  { value: "weekly", label: "Weekly" },
                  { value: "monthly-first", label: "Monthly on the first business day" },
                  { value: "monthly-last", label: "Monthly on the last business day" },
                  { value: "quarterly-first", label: "Quarterly on the first business day" },
                  { value: "custom", label: "Custom" }
                ]}
              />
            </Box>
            <Box width="small">
              <NumberInput path={`${lineFieldKey}.amount`} prefix={"$"} fixedDecimalScale decimalScale={2} placeholder="Line amount" />
            </Box>
            <Box>
              <FadeBox visible={showIcons}>
                <TrashButton onClick={() => lineHelpers.deleteAt(this.props.linesIndex)} />
              </FadeBox>
            </Box>
          </Row>
        )}
      </Draggable>
    );
  }
}
