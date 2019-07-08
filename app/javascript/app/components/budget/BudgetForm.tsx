import React from "react";
import { sortBy } from "lodash";
import { DragDropContext, DropResult } from "react-beautiful-dnd";
import { assert, ISO8601DateString } from "superlib";
import { BudgetFormSection } from "./BudgetFormSection";
import { SuperForm } from "superlib/superform";
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

const linesForSection = (doc: BudgetFormValues, sectionId: string) => {
  let list: BudgetFormLine[] = [];
  // Use a for loop here because .forEach or map or other nice things currently have a bug in automerge
  // where they don't return mutable proxies but isntead frozen objects which can't be mutated. Darn.
  for (let line of doc.budget.lines) {
    if (line.sectionId == sectionId) {
      list.push(line);
    }
  }

  return sortBy(list, line => line.sortOrder);
};

export class BudgetForm extends React.Component<{ form: SuperForm<BudgetFormValues> }> {
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

      const newSourceList = linesForSection(doc, result.source.droppableId);
      const item = assert(newSourceList.splice(result.source.index, 1)[0]);
      item.sectionId = result.destination.droppableId;

      if (result.destination.droppableId == result.source.droppableId) {
        // Moving within the same section
        newSourceList.splice(result.destination.index, 0, item);
      } else {
        // Moving into new section
        const newDestinationList = linesForSection(doc, result.destination.droppableId);
        newDestinationList.splice(result.destination.index, 0, item);
        updateSortOrders(newDestinationList);
      }
      updateSortOrders(newSourceList);
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
