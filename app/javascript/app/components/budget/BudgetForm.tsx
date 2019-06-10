import React from "react";
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
  amount: number;
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
    lines: BudgetFormLineValue[];
    sections: BudgetFormSectionValue[];
  };
}

export const EmptyLine = { description: "", amount: 0, variable: false, frequency: "monthly" };

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

      const updateSortOrders = (list: BudgetFormLineValue[]) => {
        list.forEach((line, index) => (line.sortOrder = index));
      };

      // Moving within the same section
      const newSourceList: BudgetFormLineValue[] = [];
      for (let i = 0; i < doc.budget.lines.length; i++) {
        if (doc.budget.lines[i].sectionId == result.source.droppableId) {
          newSourceList.push(doc.budget.lines[i]);
        }
      }
      const item = assert(newSourceList.splice(result.source.index, 1)[0]);

      if (result.destination.droppableId == result.source.droppableId) {
        newSourceList.splice(result.destination.index, 0, item);
        updateSortOrders(newSourceList);
      } else {
        const newDestinationList = doc.budget.lines.filter(line => line.sectionId == assert(result.destination).droppableId);
        newDestinationList.splice(result.destination.index, 0, item);
        updateSortOrders(newSourceList);
        updateSortOrders(newDestinationList);
      }
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
