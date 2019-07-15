import React from "react";
import { sortBy } from "lodash";
import { DragDropContext, DropResult } from "react-beautiful-dnd";
import { assert, ISO8601DateString } from "superlib";
import { BudgetFormSection } from "./BudgetFormSection";
import { SuperFormController } from "superlib/superform";
import { BudgetFormNewSectionList } from "./BudgetFormNewSectionList";
import { SerializedRRuleSet } from "app/lib/rrules";
import { DateTime } from "luxon";
import { Box } from "grommet";
import { BudgetFormToolbar } from "./BudgetFormToolbar";

export interface BudgetFormLineFixedValue {
  type: "fixed";
  occursAt: ISO8601DateString;
  recurrenceRules: SerializedRRuleSet | null;
  amountScenarios: {
    [key: string]: number;
  };
}

export interface BudgetFormLineSeriesValue {
  type: "series";
  scenariosEnabled: boolean;
  cells: {
    [dateTime: string]: {
      amountScenarios: {
        [key: string]: number;
      };
    };
  };
}

export type BudgetFormLineValue = BudgetFormLineFixedValue | BudgetFormLineSeriesValue;

export interface BudgetFormLine {
  id: string;
  sortOrder: number;
  description: string;
  sectionId: string;
  value: BudgetFormLineValue;
}

export interface BudgetFormSectionValues {
  name: string;
  id: string;
}

export interface BudgetFormValues {
  budget: {
    id: string;
    name: string;
    lines: BudgetFormLine[];
    sections: BudgetFormSectionValues[];
  };
}

export const EmptyLine: Partial<BudgetFormLine> = {
  description: "",
  value: { type: "fixed", amountScenarios: { default: 0 }, occursAt: DateTime.local().toISO(), recurrenceRules: null }
};

const updateSortOrders = (list: BudgetFormLine[]) => {
  for (let i = 0; i < list.length; i++) {
    list[i].sortOrder = i;
  }
};

const linesForSection = (doc: BudgetFormValues, sectionId: string, valueType: BudgetFormLine["value"]["type"]) => {
  let list: BudgetFormLine[] = [];
  // Use a for loop here because .forEach or map or other nice things currently have a bug in automerge
  // where they don't return mutable proxies but isntead frozen objects which can't be mutated. Darn.
  for (let line of doc.budget.lines) {
    if (line.sectionId == sectionId && line.value.type == valueType) {
      list.push(line);
    }
  }

  return sortBy(list, "sortOrder");
};

const sectionIdForDroppableId = (droppableId: string) => droppableId.replace(/___.*$/, "");

export class BudgetForm extends React.Component<{ form: SuperFormController<BudgetFormValues> }> {
  onDragStart = () => {
    if (window.navigator.vibrate) {
      window.navigator.vibrate(100);
    }
  };

  onDragEnd = (result: DropResult) => {
    this.props.form.dispatch(doc => {
      if (!result.destination) {
        return;
      }

      let valueType: BudgetFormLine["value"]["type"];
      switch (result.type) {
        case "SERIES-LINES": {
          valueType = "series";
          break;
        }
        case "FIXED-LINES": {
          valueType = "fixed";
          break;
        }
        default: {
          throw new Error(`Unknown droppable result type ${result.type}`);
        }
      }

      const sourceSectionId = sectionIdForDroppableId(result.source.droppableId);
      const destinationSectionId = sectionIdForDroppableId(result.destination.droppableId);

      const newSourceList = linesForSection(doc, sourceSectionId, valueType);
      let newDestinationList;
      if (result.destination.droppableId == result.source.droppableId) {
        // Moving within the same section
        newDestinationList = newSourceList;
      } else {
        // Moving into a new section
        newDestinationList = linesForSection(doc, destinationSectionId, valueType);
      }

      const item = assert(newSourceList.splice(result.source.index, 1)[0]);
      item.sectionId = destinationSectionId;
      newDestinationList.splice(result.destination.index, 0, item);

      updateSortOrders(newSourceList);
      if (result.destination.droppableId !== result.source.droppableId) {
        updateSortOrders(newDestinationList);
      }
    });
  };

  render() {
    return (
      <DragDropContext onDragEnd={this.onDragEnd} onDragStart={this.onDragStart}>
        <BudgetFormToolbar />
        {this.props.form.doc.budget.sections.map((section, sectionIndex) => (
          <BudgetFormSection key={section.id} section={section} index={sectionIndex} />
        ))}
        {this.props.form.doc.budget.sections.length == 0 && (
          <Box pad="medium">
            <BudgetFormNewSectionList />
          </Box>
        )}
      </DragDropContext>
    );
  }
}
