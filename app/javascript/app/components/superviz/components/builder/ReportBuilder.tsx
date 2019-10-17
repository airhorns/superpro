import React from "react";
import { generate } from "shortid";
import { Box } from "grommet";
import { ReportBuilderController } from "../../ReportBuilderController";
import { ReportDocument } from "../../schema";
import { SuperFormErrors } from "superlib/superform";
import { MarkdownBlockEditor } from "./MarkdownBlockEditor";
import { QueryBlockEditor } from "./QueryBlockEditor";
import { AddNewReportBlockButton } from "./AddNewReportBlockButton";
import { Warehouse } from "../../Warehouse";
import { GlobalFilterController } from "../..";
export const ReportBuilderContext = React.createContext<ReportBuilderController>({} as any);

export interface ReportBuilderProps {
  warehouse: Warehouse;
  initialDoc?: ReportDocument;
  onChange?: (doc: ReportDocument, controller: ReportBuilderController) => void;
}

export class ReportBuilder extends React.Component<ReportBuilderProps, { doc: ReportDocument; errors: SuperFormErrors<ReportDocument> }> {
  controller: ReportBuilderController;
  constructor(props: ReportBuilderProps) {
    super(props);

    const initialDoc: ReportDocument = props.initialDoc || {
      type: "document",
      id: generate(),
      blocks: [{ type: "viz_block", query: { measures: [], dimensions: [] }, viz: { type: "viz", systems: [] } }]
    };

    // Initialize the controller
    this.controller = new ReportBuilderController(
      initialDoc,
      (newDoc, _oldDoc, controller) => {
        this.setState({ doc: controller.doc, errors: controller.errors }, () => {
          console.debug("New report builder state", JSON.parse(JSON.stringify(controller.doc)));
          this.props.onChange && this.props.onChange(this.controller.doc, this.controller);
        });
      },
      props.warehouse
    );

    this.state = { doc: this.controller.doc, errors: this.controller.errors };
  }

  render() {
    return (
      <ReportBuilderContext.Provider value={this.controller}>
        <GlobalFilterController.Provider>
          <Box fill>
            {this.controller.doc.blocks.map((block, index) => {
              if (block.type == "markdown_block") {
                return <MarkdownBlockEditor key={index} block={block} index={index} />;
              } else if (block.type == "viz_block" || block.type == "table_block") {
                return <QueryBlockEditor key={index} block={block} index={index} />;
              } else {
                throw `Unknown viz document block type ${(block as any).type}`;
              }
            })}
          </Box>
          <AddNewReportBlockButton />
        </GlobalFilterController.Provider>
      </ReportBuilderContext.Provider>
    );
  }
}
