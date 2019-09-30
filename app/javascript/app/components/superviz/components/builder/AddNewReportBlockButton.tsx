import React from "react";
import { ReportBuilderContext } from "./ReportBuilder";
import { Menu } from "grommet";
import { Add } from "app/components/common/SuperproIcons";

export const AddNewReportBlockButton = (_props: {}) => {
  const controller = React.useContext(ReportBuilderContext);

  return (
    <Menu
      label="Add New Block"
      icon={<Add />}
      items={[
        { label: "Text", onClick: () => controller.appendBlock("markdown_block") },
        { label: "Visualization", onClick: () => controller.appendBlock("viz_block") },
        { label: "Table", onClick: () => controller.appendBlock("table_block") }
      ]}
    />
  );
};
