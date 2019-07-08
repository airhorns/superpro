import React from "react";
import { sortBy } from "lodash";
import { BudgetFormSectionValues, BudgetFormValues, EmptyLine, BudgetFormLine } from "./BudgetForm";
import { Heading, Box, Text } from "grommet";
import { Row, isTouchDevice } from "superlib";
import { FadeBox, AddButton, EditButton, TrashButton } from "../common";
import shortid from "shortid";
import { Droppable } from "react-beautiful-dnd";
import { BudgetLineForm } from "./BudgetLineForm";
import { useSuperForm, Input } from "superlib/superform";

type LineIndexTuple = [BudgetFormLine, number];

export const BudgetFormSection = (props: { section: BudgetFormSectionValues; index: number }) => {
  const [hovered, setHovered] = React.useState(false);
  const [editing, setEditing] = React.useState(false);
  const form = useSuperForm<BudgetFormValues>();
  const lineHelpers = form.arrayHelpers(`budget.lines`);
  const sectionHelpers = form.arrayHelpers(`budget.sections`);

  const linesForSection = sortBy(
    form.doc.budget.lines
      .map((line, lineIndex) => [line, lineIndex] as LineIndexTuple)
      .filter(([line]) => line.sectionId == props.section.id),
    ([line]) => line.sortOrder
  );

  const addLine = () =>
    lineHelpers.push({
      ...EmptyLine,
      id: shortid.generate(),
      sectionId: props.section.id,
      sortOrder: linesForSection.length
    });

  return (
    <Droppable key={props.section.id} droppableId={props.section.id} type="SECTION" direction="vertical">
      {(provided, snapshot) => (
        <Box
          pad={{ horizontal: "small", bottom: "small" }}
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
                  <AddButton onClick={addLine} />
                  <EditButton onClick={() => setEditing(!editing)} />
                  <TrashButton
                    onClick={() => {
                      form.dispatch(doc => {
                        sectionHelpers.deleteAt(props.index);
                        const lineIndexes: number[] = [];
                        doc.budget.lines.forEach((line, index) => {
                          if (line.sectionId == props.section.id) {
                            lineIndexes.push(index);
                          }
                        });
                        lineIndexes.reverse().forEach(index => lineHelpers.deleteAt(index));
                      });
                    }}
                  />
                </Row>
              </FadeBox>
            </Row>
          </Heading>
          <Box>
            {linesForSection.map(([line, lineIndex]) => (
              <BudgetLineForm key={line.id} line={line} linesIndex={lineIndex} form={form} />
            ))}
            {linesForSection.length == 0 && (
              <Row gap="small" pad="small">
                <Text color="status-unknown">Add a line...</Text>
              </Row>
            )}
          </Box>
          {provided.placeholder}
        </Box>
      )}
    </Droppable>
  );
};
