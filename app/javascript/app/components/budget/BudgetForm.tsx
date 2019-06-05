import React from "react";
import shortid from "shortid";
import { DragDropContext, Droppable, DropResult } from "react-beautiful-dnd";
import { Formant, SubmitBar, FieldArray } from "flurishlib/formant";
import { Heading, Box, Button, Text } from "grommet";
import { HelpTip, Row, assert } from "flurishlib";
import { FormikProps, getIn } from "formik";
import { Add } from "../common/FlurishIcons";
import { BudgetLineForm } from "./BudgetLineForm";
import _ from "lodash";

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

export interface BudgetFormValues {
  budget: {
    id?: string;
    sections: {
      name: string;
      key: string;
      lines: BudgetFormLineValue[];
    }[];
  };
}

const EmptyLine = { description: "", amount: 0, variable: false, frequency: "monthly" };

export class BudgetForm extends React.Component<{ form: FormikProps<BudgetFormValues> }> {
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
    return (
      <DragDropContext onDragEnd={this.onDragEnd}>
        {this.props.form.values.budget.sections.map((section, sectionIndex) => (
          <Droppable key={section.key} droppableId={section.key} type="SECTION" direction="vertical">
            {(provided, snapshot) => (
              <Box
                pad="small"
                ref={provided.innerRef as any}
                background={snapshot.isDraggingOver ? "light-1" : "white"}
                {...provided.droppableProps}
              >
                <Heading level="3">
                  <Formant.Input name={`budget.sections.${sectionIndex}.name`} />
                </Heading>
                <FieldArray name={`budget.sections.${sectionIndex}.lines`}>
                  {arrayHelpers => (
                    <>
                      <Box>
                        {section.lines.map((line, lineIndex) => (
                          <BudgetLineForm
                            key={line.key}
                            line={line}
                            index={lineIndex}
                            lineFieldKey={`budget.sections.${sectionIndex}.lines.${lineIndex}`}
                            arrayHelpers={arrayHelpers}
                          />
                        ))}
                      </Box>
                      {provided.placeholder}

                      <Box pad="small" width="medium">
                        <Button onClick={() => arrayHelpers.push({ ...EmptyLine, key: shortid.generate() })}>
                          <Text color="status-unknown">Add a line...</Text>
                        </Button>
                      </Box>
                    </>
                  )}
                </FieldArray>
              </Box>
            )}
          </Droppable>
        ))}
        <FieldArray name="budget.sections">
          {arrayHelpers => {
            if (this.props.form.values.budget.sections.length > 2) {
              return (
                <Box>
                  <Heading level="3">Add a section</Heading>
                  <Row wrap>
                    {BudgetSectionSuggestions.map(suggestion => (
                      <Button
                        key={suggestion.name}
                        as="div"
                        onClick={(_e: React.SyntheticEvent) =>
                          arrayHelpers.push({
                            name: suggestion.name,
                            key: shortid.generate(),
                            lines: [{ ...EmptyLine, key: shortid.generate() }]
                          })
                        }
                        margin="small"
                        label={
                          <Row justify="between" gap="small">
                            {suggestion.name}
                            <HelpTip text={suggestion.description} />
                          </Row>
                        }
                      />
                    ))}
                  </Row>
                </Box>
              );
            } else {
              return (
                <Box>
                  <Heading level="3">Add sections</Heading>
                  {BudgetSectionSuggestions.map(suggestion => (
                    <Box pad="small" key={suggestion.name}>
                      <Heading level="4">{suggestion.name}</Heading>
                      <Text>{suggestion.description}</Text>
                      <Box align="start">
                        <Button
                          key={suggestion.name}
                          as="div"
                          onClick={(_e: React.SyntheticEvent) =>
                            arrayHelpers.push({
                              name: suggestion.name,
                              key: shortid.generate(),
                              lines: [{ ...EmptyLine, key: shortid.generate() }]
                            })
                          }
                          margin="small"
                          icon={<Add />}
                          label={`Add ${suggestion.name}`}
                        />
                      </Box>
                    </Box>
                  ))}
                </Box>
              );
            }
          }}
        </FieldArray>
        <SubmitBar />
      </DragDropContext>
    );
  }
}
