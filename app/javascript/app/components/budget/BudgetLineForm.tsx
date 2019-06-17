import React from "react";
import { Draggable } from "react-beautiful-dnd";
import { TrashButton, FadeBox, ScenarioInput } from "../common";
import { Box } from "grommet";
import { Row, shallowSubsetEqual, shallowEqual, isTouchDevice } from "flurishlib";
import { BudgetFormLineValue, BudgetFormValues } from "./BudgetForm";
import { DragHandle } from "../common/FlurishIcons";
import { SuperForm, Input, SuperDatePicker } from "flurishlib/superform";
import { RecurrenceSelect } from "./RecurrenceSelect";

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
    const value =
      !shallowEqual(this.state, nextState) ||
      !shallowSubsetEqual(["line", "linesIndex"], this.props, nextProps) ||
      !shallowEqual(this.props.line, nextProps.line);
    return value;
  }

  render() {
    const showIcons = isTouchDevice() || this.state.hovered;
    const lineFieldKey = `budget.lines.${this.props.linesIndex}`;
    const lineHelpers = this.props.form.arrayHelpers("budget.lines");

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
            <Box flex style={{ minWidth: "150px" }}>
              <Input path={`${lineFieldKey}.description`} placeholder="Line description" />
            </Box>
            <Box width="265px">
              <SuperDatePicker path={`${lineFieldKey}.occursAt`} />
            </Box>
            <Box width="small">
              <RecurrenceSelect path={`${lineFieldKey}.recurrenceRules`} />
            </Box>
            <Box width="small">
              <ScenarioInput
                path={`${lineFieldKey}.amountScenarios`}
                prefix={"$"}
                fixedDecimalScale
                decimalScale={2}
                storeAsSubunits
                placeholder="Line amount"
              />
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
