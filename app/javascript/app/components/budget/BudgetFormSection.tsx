import React from "react";
import { sortBy, partition } from "lodash";
import shortid from "shortid";
import { Heading, Box, Text } from "grommet";
import { Droppable } from "react-beautiful-dnd";
import { Row, isTouchDevice } from "superlib";
import { useSuperForm, Input } from "superlib/superform";
import { FadeBox, AddButton, EditButton, TrashButton } from "../common";
import { BudgetFormSectionValues, BudgetFormValues, EmptyLine, BudgetFormLine } from "./BudgetForm";
import { BudgetLineForm } from "./BudgetLineForm";
import { SeriesLinesSheet } from "./SeriesLinesSheet";

export type LineIndexTuple = [BudgetFormLine, number];

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

  const [fixedLinesForSection, seriesLinesForSection] = partition(linesForSection, ([line]) => line.value.type == "fixed");

  const addLine = () =>
    lineHelpers.push({
      ...EmptyLine,
      id: shortid.generate(),
      sectionId: props.section.id,
      sortOrder: linesForSection.length
    });

  return (
    <Box pad={{ horizontal: "small", bottom: "small" }} onMouseEnter={() => setHovered(true)} onMouseLeave={() => setHovered(false)}>
      <Heading level="3">
        <Row>
          {(editing && <Input path={`budget.sections.${props.index}.name`} onBlur={() => setEditing(false)} />) || props.section.name}
          <FadeBox visible={isTouchDevice() || hovered}>
            <Row margin={{ left: "small" }} gap="small">
              <EditButton onClick={() => setEditing(!editing)} />
              <AddButton onClick={addLine} />
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
      <Droppable droppableId={`${props.section.id}___fixed-lines`} type="FIXED-LINES" direction="vertical">
        {(provided, snapshot) => (
          <Box ref={provided.innerRef as any} background={snapshot.isDraggingOver ? "light-1" : "white"} {...provided.droppableProps}>
            <Box>
              {fixedLinesForSection.map(([line, lineIndex]) => (
                <BudgetLineForm key={line.id} line={line} linesIndex={lineIndex} form={form} />
              ))}
              {linesForSection.length == 0 && (
                <Row gap="small" pad="small">
                  <Text color="status-unknown">Add a line...</Text>
                </Row>
              )}
              {provided.placeholder}
            </Box>
          </Box>
        )}
      </Droppable>
      <Droppable droppableId={`${props.section.id}___series-lines`} type="SERIES-LINES" direction="vertical">
        {(provided, snapshot) => (
          <Box ref={provided.innerRef as any} background={snapshot.isDraggingOver ? "light-1" : "white"} {...provided.droppableProps}>
            {seriesLinesForSection.length > 0 && <SeriesLinesSheet lines={seriesLinesForSection}>{provided.placeholder}</SeriesLinesSheet>}
            {seriesLinesForSection.length == 0 && provided.placeholder}
          </Box>
        )}
      </Droppable>
    </Box>
  );
};
