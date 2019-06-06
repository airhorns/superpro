import React from "react";
import _ from "lodash";
import shortid from "shortid";
import { DragDropContext, DropResult } from "react-beautiful-dnd";
import { SubmitBar, FieldArray } from "flurishlib/formant";
import { Heading, Box, Button, Text } from "grommet";
import { HelpTip, Row, assert } from "flurishlib";
import { FormikProps, getIn } from "formik";
import { Add } from "../common/FlurishIcons";
import { BudgetFormSection } from "./BudgetFormSection";

const Lorem =
  "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum";
const BudgetSectionSuggestions: { name: string; description: string; suggestedItems: { name: string }[] }[] = [
  {
    name: "Services",
    description: Lorem,
    suggestedItems: []
  },
  {
    name: "Facilities",
    description: "This other thing",
    suggestedItems: []
  },
  {
    name: "Legal",
    description: Lorem,
    suggestedItems: []
  },
  {
    name: "Fixed Assets",
    description: "Another description",
    suggestedItems: []
  },
  {
    name: "Materials",
    description: "Whatever",
    suggestedItems: []
  }
];

export interface BudgetFormLineValue {
  id?: string;
  description: string;
  key: string;
  amount: number;
  variable: boolean;
  frequency: string;
}

export interface BudgetFormSectionValue {
  name: string;
  key: string;
  lines: BudgetFormLineValue[];
}
export interface BudgetFormValues {
  budget: {
    id?: string;
    sections: BudgetFormSectionValue[];
  };
}

export const EmptyLine = { description: "", amount: 0, variable: false, frequency: "monthly" };

export class BudgetForm extends React.Component<{ form: FormikProps<BudgetFormValues> }> {
  onDragStart = () => {
    if (window.navigator.vibrate) {
      window.navigator.vibrate(100);
    }
  };

  onDragEnd = (result: DropResult) => {
    if (!result.destination) {
      return;
    }
    const sourceKey = `budget.sections.${_.findIndex(this.props.form.values.budget.sections, { key: result.source.droppableId })}.lines`;
    const newSource = _.clone(assert(getIn(this.props.form.values, sourceKey)));
    const item = newSource.splice(result.source.index, 1)[0];
    this.props.form.setFieldValue(sourceKey, newSource);

    const destKey = `budget.sections.${_.findIndex(this.props.form.values.budget.sections, { key: result.destination.droppableId })}.lines`;
    const newDest =
      result.destination.droppableId == result.source.droppableId ? newSource : _.clone(assert(getIn(this.props.form.values, destKey)));
    newDest.splice(result.destination.index, 0, item);
    this.props.form.setFieldValue(destKey, newDest);
  };

  render() {
    const existingSections = new Set(_.uniq(this.props.form.values.budget.sections.map(section => section.name)));
    const suggestedSections = _.filter(BudgetSectionSuggestions, suggestion => !existingSections.has(suggestion.name));

    return (
      <DragDropContext onDragEnd={this.onDragEnd} onDragStart={this.onDragStart}>
        {this.props.form.values.budget.sections.map((section, sectionIndex) => (
          <BudgetFormSection key={section.key} section={section} index={sectionIndex} form={this.props.form} />
        ))}
        <FieldArray name="budget.sections">
          {arrayHelpers => (
            <Box>
              <Heading level="3">Add sections</Heading>
              {suggestedSections.map(suggestion => {
                const onClick = (_e: React.SyntheticEvent) =>
                  arrayHelpers.push({
                    name: suggestion.name,
                    key: shortid.generate(),
                    lines: [{ ...EmptyLine, key: shortid.generate() }]
                  });

                if (this.props.form.values.budget.sections.length > 2) {
                  return (
                    <Box width="medium" key={suggestion.name}>
                      <Button
                        as="div"
                        onClick={onClick}
                        margin="small"
                        label={
                          <Row justify="between" gap="small">
                            {suggestion.name}
                            <HelpTip text={suggestion.description} />
                          </Row>
                        }
                      />
                    </Box>
                  );
                } else {
                  return (
                    <Box pad="small" key={suggestion.name}>
                      <Heading level="4">{suggestion.name}</Heading>
                      <Text>{suggestion.description}</Text>
                      <Box align="start">
                        <Button
                          key={suggestion.name}
                          as="div"
                          onClick={onClick}
                          margin="small"
                          icon={<Add />}
                          label={`Add ${suggestion.name}`}
                        />
                      </Box>
                    </Box>
                  );
                }
              })}
              {(() => {
                const onClick = (_e: React.SyntheticEvent) =>
                  arrayHelpers.push({
                    name: "New Section",
                    key: shortid.generate(),
                    lines: [{ ...EmptyLine, key: shortid.generate() }]
                  });

                return (
                  <Box width="medium">
                    <Button
                      as="div"
                      onClick={onClick}
                      margin="small"
                      label={
                        <Row justify="between" gap="small">
                          Add Custom
                          <HelpTip text="A custom section that can represent any other kind of expense or revenue in your budget." />
                        </Row>
                      }
                    />
                  </Box>
                );
              })()}
            </Box>
          )}
        </FieldArray>
        <SubmitBar />
      </DragDropContext>
    );
  }
}
