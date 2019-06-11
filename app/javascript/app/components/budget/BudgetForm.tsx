import React from "react";
import { sortBy } from "lodash";
import { DragDropContext, DropResult } from "react-beautiful-dnd";
import { assert } from "flurishlib";
import { BudgetFormSection } from "./BudgetFormSection";
import { SuperForm } from "flurishlib/superform";
import { BudgetFormNewSectionlist } from "./BudgetFormNewSectionList";
import { SerializedRRuleSet } from "app/lib/rrules";

export interface BudgetFormLineValue {
  id: string;
  sortOrder: number;
  description: string;
  amountScenarios: {
    [key: string]: number;
  };
  recurrenceRules: SerializedRRuleSet | null;
  sectionId: string;
}

export interface BudgetFormSectionValue {
  name: string;
  id: string;
}

export interface BudgetFormValues {
  budget: {
    id: string;
    name: string;
    lines: BudgetFormLineValue[];
    sections: BudgetFormSectionValue[];
  };
}

export const EmptyLine = { description: "", amountScenarios: {} };

const updateSortOrders = (list: BudgetFormLineValue[]) => {
  for (let i = 0; i < list.length; i++) {
    list[i].sortOrder = i;
  }
};

const linesForSection = (doc: BudgetFormValues, sectionId: string) => {
  let list: BudgetFormLineValue[] = [];
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
        {this.props.form.doc.budget.sections.map((section, sectionIndex) => (
          <BudgetFormSection key={section.id} section={section} index={sectionIndex} />
        ))}
        <BudgetFormNewSectionlist />
      </DragDropContext>
    );
  }
}
