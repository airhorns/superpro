import React from "react";
import shortid from "shortid";
import { DragDropContext, Draggable, Droppable, DropResult } from "react-beautiful-dnd";
import { Page, TrashButton } from "../common";
import { Formant, SubmitBar, FieldArray } from "flurishlib/formant";
import { Heading, Box, Button, Text } from "grommet";
import { HelpTip, Row } from "flurishlib";
import { FormikProps } from "formik";
import { Add } from "../common/FlurishIcons";

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

interface BudgetFormValues {
  budget: {
    sections: {
      name: string;
      key: string;
      lines: {
        name: string;
        key: string;
        amount: number;
        variable: boolean;
        frequency: "daily" | "weekly" | "monthly" | "quarterly" | "yearly";
      }[];
    }[];
  };
}

const EmptyLine = { name: "", amount: 0, variable: false, frequency: "monthly" };

export default class NewBudgetPage extends Page {
  onDragEnd = (form: FormikProps<BudgetFormValues>, result: DropResult) => {
    if (!result.destination) {
      return;
    }
  };

  render() {
    return (
      <Page.Layout title="Budget">
        <Formant<BudgetFormValues> initialValues={{ budget: { sections: [] } }} onSubmit={console.log}>
          {form => (
            <DragDropContext onDragEnd={result => this.onDragEnd(form, result)}>
              {form.values.budget.sections.map((section, sectionIndex) => (
                <Droppable key={section.key} droppableId={`section-${section.key}`} type="SECTION" direction="vertical">
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
                                <Draggable draggableId={`line-${line.key}`} index={lineIndex} key={line.key}>
                                  {provided => (
                                    <Row
                                      pad="small"
                                      gap="medium"
                                      wrap
                                      ref={provided.innerRef as any}
                                      {...provided.draggableProps}
                                      {...provided.dragHandleProps}
                                    >
                                      <Box width="medium">
                                        <Formant.Input
                                          name={`budget.sections.${sectionIndex}.lines.${lineIndex}.name`}
                                          placeholder="Line description"
                                        />
                                      </Box>
                                      <Box width="small">
                                        <Formant.Select
                                          name={`budget.sections.${sectionIndex}.lines.${lineIndex}.variable`}
                                          options={[{ value: true, label: "Variable" }, { value: false, label: "Fixed" }]}
                                        />
                                      </Box>
                                      <Box width="small">
                                        <Formant.Select
                                          name={`budget.sections.${sectionIndex}.lines.${lineIndex}.frequency`}
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
                                          name={`budget.sections.${sectionIndex}.lines.${lineIndex}.amount`}
                                          prefix={"$"}
                                          fixedDecimalScale
                                          decimalScale={2}
                                          placeholder="Line amount"
                                        />
                                      </Box>
                                      <Box>
                                        <TrashButton onClick={() => arrayHelpers.remove(lineIndex)} />
                                      </Box>
                                    </Row>
                                  )}
                                </Draggable>
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
                  if (form.values.budget.sections.length > 2) {
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
          )}
        </Formant>
      </Page.Layout>
    );
  }
}
