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
    expect(assert(controller.selection).anchor).toEqual({ row: 1, column: 1 });
    expect(assert(controller.selection).focus).toEqual({ row: 1, column: 1 });
  });

  test("the selection can be moved by a delta that can't go past the edges of the sheet", () => {
    controller.moveSelectionDelta(1, 1);
    expect(assert(controller.selection).anchor).toEqual({ row: 1, column: 1 });
    expect(assert(controller.selection).focus).toEqual({ row: 1, column: 1 });

    controller.moveSelectionDelta(1, 0);
    expect(assert(controller.selection).anchor).toEqual({ row: 2, column: 1 });
    expect(assert(controller.selection).focus).toEqual({ row: 2, column: 1 });

    controller.moveSelectionDelta(0, -3);
    expect(assert(controller.selection).anchor).toEqual({ row: 2, column: 0 });
    expect(assert(controller.selection).focus).toEqual({ row: 2, column: 0 });

    controller.moveSelectionDelta(1000, 0);
    expect(assert(controller.selection).anchor).toEqual({ row: 4, column: 0 });
    expect(assert(controller.selection).focus).toEqual({ row: 4, column: 0 });
  });

  test("the edit can be toggled", () => {
    controller.moveSelectionTo({ row: 4, column: 1 }, { row: 4, column: 1 }).toggleEdit();
    expect(assert(controller.edit)).toEqual({ row: 4, column: 1 });
    controller.toggleEdit();
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
    expect(assert(controller.selection).anchor).toEqual({ row: 1, column: 3 });
    expect(assert(controller.selection).focus).toEqual({ row: 1, column: 3 });
  });

  test("the selection can't be set to a hole", () => {
    controller.moveSelectionTo({ row: 0, column: 0 }, { row: 0, column: 0 });
    expect(assert(controller.selection).anchor).toEqual({ row: 0, column: 2 });
    expect(assert(controller.selection).focus).toEqual({ row: 0, column: 2 });
  });

  test("the selection can't be moved to a hole", () => {
    controller.moveSelectionDelta(0, -1);
    expect(assert(controller.selection).anchor).toEqual({ row: 0, column: 2 });
    expect(assert(controller.selection).focus).toEqual({ row: 0, column: 2 });
  });
});

describe("a spreadsheet with a rowspan", () => {
  beforeEach(() => {
    // Register a non rowspanning cell at 4,0 that can be used to test exiting out the bottom
    controller.registerCell(
      {
        ref: { current: null },
        path: `values.0.0`,
        row: 0,
        column: 0,
        handleKeyDown: () => {}
      },
      () => {}
    );

    // Register a rowspanning cell at 1,0 that goes down 3 rows that can be used to exit out the top
    controller.registerCell(
      {
        ref: { current: null },
        path: `values.1.0`,
        row: 1,
        column: 0,
        rowSpan: 3,
        handleKeyDown: () => {}
      },
      () => {}
    );

    // Register a non rowspanning cell at 4,0 that can be used to test exiting out the bottom
    controller.registerCell(
      {
        ref: { current: null },
        path: `values.4.0`,
        row: 4,
        column: 0,
        handleKeyDown: () => {}
      },
      () => {}
    );

    range(0, 5).forEach(row => {
      range(1, 6).forEach(column => {
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

    controller.moveSelectionTo({ row: 2, column: 1 }, { row: 2, column: 1 });
  });

  test("the selection can be set and moved around", () => {
    controller.moveSelectionTo({ row: 1, column: 3 }, { row: 1, column: 3 });
    expect(assert(controller.selection).anchor).toEqual({ row: 1, column: 3 });
    expect(assert(controller.selection).focus).toEqual({ row: 1, column: 3 });
  });

  test("the selection can be moved into a rowspan'd cell from the same row its in", () => {
    controller.moveSelectionDelta(-1, -1);
    expect(assert(controller.selection).anchor).toEqual({ row: 1, column: 0 });
    expect(assert(controller.selection).focus).toEqual({ row: 1, column: 0 });

    expect(Array.from(controller.getSelectedCellRegistrations())).toContain(assert(controller.cells.get(1)).get(0));
  });

  test("the selection can be moved into a rowspan'd cell from one of the spanned rows", () => {
    controller.moveSelectionDelta(0, -1);
    expect(assert(controller.selection).anchor).toEqual({ row: 2, column: 0 });
    expect(assert(controller.selection).focus).toEqual({ row: 2, column: 0 });

    expect(Array.from(controller.getSelectedCellRegistrations())).toContain(assert(controller.cells.get(1)).get(0));
  });

  test("after selecting a rowspan from spanned coordinates, the edit can be toggled", () => {
    controller.moveSelectionDelta(0, -1);
    expect(assert(controller.selection).anchor).toEqual({ row: 2, column: 0 });
    expect(assert(controller.selection).focus).toEqual({ row: 2, column: 0 });

    controller.toggleEdit();
    expect(controller.edit).toEqual({ row: 1, column: 0 });
    controller.toggleEdit();
    expect(controller.edit).toBeNull();
  });

  test("the selection can be moved out of a rowspan'd cell upwards", () => {
    controller.moveSelectionDelta(0, -1);
    expect(assert(controller.selection).anchor).toEqual({ row: 2, column: 0 });
    expect(assert(controller.selection).focus).toEqual({ row: 2, column: 0 });
    controller.moveSelectionDelta(-1, 0);
    expect(assert(controller.selection).anchor).toEqual({ row: 0, column: 0 });
    expect(assert(controller.selection).focus).toEqual({ row: 0, column: 0 });
  });

  test("the selection can be moved out of a rowspan'd cell downwards", () => {
    controller.moveSelectionDelta(0, -1);
    expect(assert(controller.selection).anchor).toEqual({ row: 2, column: 0 });
    expect(assert(controller.selection).focus).toEqual({ row: 2, column: 0 });
    controller.moveSelectionDelta(1, 0);
    expect(assert(controller.selection).anchor).toEqual({ row: 4, column: 0 });
    expect(assert(controller.selection).focus).toEqual({ row: 4, column: 0 });
  });

  test("the selection can be moved out of a rowspan'd cell sideways", () => {
    controller.moveSelectionDelta(0, -1);
    expect(assert(controller.selection).anchor).toEqual({ row: 2, column: 0 });
    expect(assert(controller.selection).focus).toEqual({ row: 2, column: 0 });
    controller.moveSelectionDelta(0, 1);
    expect(assert(controller.selection).anchor).toEqual({ row: 2, column: 1 });
    expect(assert(controller.selection).focus).toEqual({ row: 2, column: 1 });
  });
});
