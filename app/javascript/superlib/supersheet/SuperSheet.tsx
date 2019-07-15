import React from "react";
import { StyledDataGrid, StyledDataGridContainer } from "./StyledDataGrid";
import { useSuperForm } from "superlib/superform";
import { SheetUpdateCallback, SuperSheetController, CellRegistration } from "./SuperSheetController";

export const SheetContext = React.createContext<SuperSheetController>(null as any);

export const useSheet = () => {
  const sheet = React.useContext(SheetContext);

  if (!sheet) {
    throw new Error("Can't use sheet components outside a <Sheet/> wrapper");
  }

  return sheet;
};

export const useCell = <E extends HTMLElement>(registration: CellRegistration) => {
  const sheet = useSheet();
  const form = useSuperForm<any>();
  const [sheetVersion, setSheetVersion] = React.useState<number>(0);

  React.useEffect(() => {
    const sheetUpdated: SheetUpdateCallback = (event: { version: number }) => {
      setSheetVersion(event.version);
    };

    sheet.registerCell(registration, sheetUpdated);

    return () => {
      sheet.unregisterCell(registration, sheetUpdated);
    };
  });

  return {
    sheet,
    sheetVersion,
    form,
    editing: sheet.isEditing(registration.row, registration.column),
    selected: sheet.isSelected(registration.row, registration.column)
  };
};

interface SuperSheetState {
  version: number;
}

export class SuperSheet extends React.Component<{}, SuperSheetState> {
  state: SuperSheetState = { version: 0 };
  controller: SuperSheetController;

  constructor(props: {}) {
    super(props);
    this.controller = new SuperSheetController(this.onChange);
  }

  onChange = (controller: SuperSheetController) => {
    this.setState({ version: controller.version });
  };

  render() {
    return (
      <StyledDataGridContainer
        tabIndex={0}
        ref={this.controller.containerRef}
        onKeyDown={this.controller.handleKeyDown}
        onBlur={this.controller.handleContainerBlur}
      >
        <SheetContext.Provider value={this.controller}>
          <StyledDataGrid onKeyDown={this.controller.handleKeyDown}>{this.props.children}</StyledDataGrid>
        </SheetContext.Provider>
      </StyledDataGridContainer>
    );
  }
}
