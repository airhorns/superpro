import React from "react";
import _ from "lodash";
import { BudgetFormSectionValue, BudgetFormValues, EmptyLine } from "./BudgetForm";
import { FormikProps, FieldArray } from "formik";
import { Heading, Box, Button } from "grommet";
import { Row, isTouchDevice } from "flurishlib";
import { Formant } from "flurishlib/formant";
import { FadeBox, AddButton, EditButton, TrashButton } from "../common";
import shortid from "shortid";
import { Droppable } from "react-beautiful-dnd";
import { BudgetLineForm } from "./BudgetLineForm";

export const BudgetFormSection = React.memo(
  (props: { section: BudgetFormSectionValue; index: number; form: FormikProps<BudgetFormValues> }) => {
    const [hovered, setHovered] = React.useState(false);
    const [editing, setEditing] = React.useState(false);

    return (
      <Droppable key={props.section.key} droppableId={props.section.key} type="SECTION" direction="vertical">
        {(provided, snapshot) => (
          <Box
            pad="small"
            ref={provided.innerRef as any}
            background={snapshot.isDraggingOver ? "light-1" : "white"}
            {...provided.droppableProps}
            onMouseEnter={() => !snapshot.isDraggingOver && setHovered(true)}
            onMouseLeave={() => setHovered(false)}
          >
            <FieldArray name={`budget.sections.${props.index}.lines`}>
              {arrayHelpers => (
                <>
                  <Heading level="3">
                    <Row>
                      {(editing && <Formant.Input name={`budget.sections.${props.index}.name`} onBlur={() => setEditing(false)} />) ||
                        props.section.name}
                      <FadeBox visible={isTouchDevice() || hovered}>
                        <Row margin={{ left: "small" }} gap="small">
                          <AddButton onClick={() => arrayHelpers.push({ ...EmptyLine, key: shortid.generate() })} />
                          <EditButton onClick={() => setEditing(!editing)} />
                          <TrashButton
                            onClick={() => {
                              const newSections = _.clone(props.form.values.budget.sections);
                              newSections.splice(props.index, 1);
                              props.form.setFieldValue("budget.sections", newSections);
                            }}
                          />
                        </Row>
                      </FadeBox>
                    </Row>
                  </Heading>
                  <Box>
                    {props.section.lines.map((line, lineIndex) => (
                      <BudgetLineForm
                        key={line.key}
                        line={line}
                        index={lineIndex}
                        lineFieldKey={`budget.sections.${props.index}.lines.${lineIndex}`}
                        arrayHelpers={arrayHelpers}
                      />
                    ))}
                  </Box>
                  {provided.placeholder}
                </>
              )}
            </FieldArray>
          </Box>
        )}
      </Droppable>
    );
  }
);
