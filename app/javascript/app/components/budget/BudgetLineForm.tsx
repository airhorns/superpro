import React from "react";
import { Draggable } from "react-beautiful-dnd";
import { TrashButton, FadeBox } from "../common";
import { Formant } from "flurishlib/formant";
import { Box } from "grommet";
import { Row, shallowSubsetEqual, shallowEqual, isTouchDevice } from "flurishlib";
import { BudgetFormLineValue } from "./BudgetForm";
import { FieldArrayRenderProps } from "formik";
import { DragHandle } from "../common/FlurishIcons";

export interface BudgetLineFormProps {
  lineFieldKey: string;
  line: BudgetFormLineValue;
  index: number;
  arrayHelpers: FieldArrayRenderProps;
}

export interface BudgetLineFormState {
  hovered: boolean;
}

export class BudgetLineForm extends React.Component<BudgetLineFormProps, BudgetLineFormState> {
  state: BudgetLineFormState = { hovered: false };

  shouldComponentUpdate(nextProps: BudgetLineFormProps, nextState: BudgetLineFormState) {
    return !shallowEqual(this.state, nextState) || !shallowSubsetEqual(["line", "index", "lineFieldKey"], this.props, nextProps);
  }

  render() {
    const showIcons = isTouchDevice() || this.state.hovered;

    return (
      <Draggable draggableId={`line-${this.props.line.key}`} index={this.props.index}>
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
              <Formant.Input fast name={`${this.props.lineFieldKey}.description`} placeholder="Line description" />
            </Box>
            <Box width="small">
              <Formant.Select
                fast
                name={`${this.props.lineFieldKey}.variable`}
                options={[{ value: true, label: "Variable" }, { value: false, label: "Fixed" }]}
              />
            </Box>
            <Box width="small">
              <Formant.Select
                fast
                name={`${this.props.lineFieldKey}.frequency`}
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
              <Formant.NumberInput
                fast
                name={`${this.props.lineFieldKey}.amount`}
                prefix={"$"}
                fixedDecimalScale
                decimalScale={2}
                placeholder="Line amount"
              />
            </Box>
            <Box>
              <FadeBox visible={showIcons}>
                <TrashButton onClick={() => this.props.arrayHelpers.remove(this.props.index)} />
              </FadeBox>
            </Box>
          </Row>
        )}
      </Draggable>
    );
  }
}
