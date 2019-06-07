import React from "react";
import _ from "lodash";
import { BudgetFormSectionValue, BudgetFormValues, EmptyLine } from "./BudgetForm";
import { Heading, Box } from "grommet";
import { Row, isTouchDevice } from "flurishlib";
import { FadeBox, AddButton, EditButton, TrashButton } from "../common";
import shortid from "shortid";
import { Droppable } from "react-beautiful-dnd";
import { BudgetLineForm } from "./BudgetLineForm";
import { useSuperForm, Input } from "flurishlib/superform";

export const BudgetFormSection = React.memo((props: { section: BudgetFormSectionValue; index: number }) => {
  const [hovered, setHovered] = React.useState(false);
  const [editing, setEditing] = React.useState(false);
  const form = useSuperForm<BudgetFormValues>();
  const lineHelpers = form.arrayHelpers(`budget.sections.${props.index}.lines`);

  return (
    <Droppable key={props.section.id} droppableId={props.section.id} type="SECTION" direction="vertical">
      {(provided, snapshot) => (
        <Box
          pad="small"
          ref={provided.innerRef as any}
          background={snapshot.isDraggingOver ? "light-1" : "white"}
          {...provided.droppableProps}
          onMouseEnter={() => !snapshot.isDraggingOver && setHovered(true)}
          onMouseLeave={() => setHovered(false)}
        >
          <Heading level="3">
            <Row>
              {(editing && <Input path={`budget.sections.${props.index}.name`} onBlur={() => setEditing(false)} />) || props.section.name}
              <FadeBox visible={isTouchDevice() || hovered}>
                <Row margin={{ left: "small" }} gap="small">
                  <AddButton onClick={() => lineHelpers.push({ ...EmptyLine, key: shortid.generate() })} />
                  <EditButton onClick={() => setEditing(!editing)} />
                  <TrashButton
                    onClick={() => {
                      const newSections = _.clone(form.doc.budget.sections);
                      newSections.splice(props.index, 1);
                      form.setValue("budget.sections", newSections);
                    }}
                  />
                </Row>
              </FadeBox>
            </Row>
          </Heading>
          <Box>
            {form.doc.budget.lines.map(
              (line, lineIndex) =>
                line.sectionId == props.section.id && <BudgetLineForm key={line.id} line={line} linesIndex={lineIndex} form={form} />
            )}
          </Box>
          {provided.placeholder}
        </Box>
      )}
    </Droppable>
  );
});
