import { range } from "lodash";
import { SuperSheetController } from "../SuperSheetController";
import { assert } from "../../utils";

let controller!: SuperSheetController;
let onChange!: VoidFunction;

beforeEach(() => {
  onChange = jest.fn();
  controller = new SuperSheetController(onChange);
});

describe("a basic spreadsheet", () => {
  beforeEach(() => {
    range(0, 5).forEach(row => {
      range(0, 6).forEach(column => {
        controller.registerCell(
          {
            ref: { current: null },
            path: `values.${row}.${column}`,
            row,
            column,
            handleKeyDown: () => {}
          },
          () => {}
        );
      });
    });

    controller.moveSelectionTo({ row: 0, column: 0 }, { row: 0, column: 0 });
  });

  test("the selection can be set and moved around", () => {
    controller.moveSelectionTo({ row: 1, column: 1 }, { row: 1, column: 1 });
    expect(assert(controller.selection).start).toEqual({ row: 1, column: 1 });
    expect(assert(controller.selection).end).toEqual({ row: 1, column: 1 });
  });

  test("the selection can be moved by a delta that can't go past the edges of the sheet", () => {
    controller.moveSelectionDelta(1, 1);
    expect(assert(controller.selection).start).toEqual({ row: 1, column: 1 });
    expect(assert(controller.selection).end).toEqual({ row: 1, column: 1 });

    controller.moveSelectionDelta(1, 0);
    expect(assert(controller.selection).start).toEqual({ row: 2, column: 1 });
    expect(assert(controller.selection).end).toEqual({ row: 2, column: 1 });

    controller.moveSelectionDelta(0, -3);
    expect(assert(controller.selection).start).toEqual({ row: 2, column: 0 });
    expect(assert(controller.selection).end).toEqual({ row: 2, column: 0 });

    controller.moveSelectionDelta(1000, 0);
    expect(assert(controller.selection).start).toEqual({ row: 4, column: 0 });
    expect(assert(controller.selection).end).toEqual({ row: 4, column: 0 });
  });

  test("the edit can be toggled", () => {
    controller.toggleEdit(4, 1);
    expect(assert(controller.edit)).toEqual({ row: 4, column: 1 });
    controller.toggleEdit(4, 1);
    expect(controller.edit).toBeNull();
  });
});

describe("a spreadsheet with a hole in all columns", () => {
  beforeEach(() => {
    range(0, 3).forEach(row => {
      range(0, 6).forEach(column => {
        controller.registerCell(
          {
            ref: { current: null },
            path: `values.${row}.${column + 2}`,
            row,
            column: column + 2,
            handleKeyDown: () => {}
          },
          () => {}
        );
      });
    });

    controller.moveSelectionTo({ row: 0, column: 2 }, { row: 0, column: 2 });
  });

  test("the selection can be set and moved around", () => {
    controller.moveSelectionTo({ row: 1, column: 3 }, { row: 1, column: 3 });
    expect(assert(controller.selection).start).toEqual({ row: 1, column: 3 });
    expect(assert(controller.selection).end).toEqual({ row: 1, column: 3 });
  });

  test("the selection can't be set to a hole", () => {
    controller.moveSelectionTo({ row: 0, column: 0 }, { row: 0, column: 0 });
    expect(assert(controller.selection).start).toEqual({ row: 0, column: 2 });
    expect(assert(controller.selection).end).toEqual({ row: 0, column: 2 });
  });

  test("the selection can't be moved to a hole", () => {
    controller.moveSelectionDelta(0, -1);
    expect(assert(controller.selection).start).toEqual({ row: 0, column: 2 });
    expect(assert(controller.selection).end).toEqual({ row: 0, column: 2 });
  });
});
