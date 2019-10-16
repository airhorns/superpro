import React from "react";
import { ReportDocument, TableBlock } from "../../schema";
import { GetWarehouseData } from "../GetWarehouseData";
import { WaterTable } from "superlib/WaterTable";
import { Box, Heading } from "grommet";

export const TableBlockRenderer = (props: { doc: ReportDocument; block: TableBlock }) => (
  <GetWarehouseData query={props.block.query}>
    {result => {
      const tableColumns = Object.values(result.outputIntrospection.fields).map(field => ({
        key: field.id,
        header: field.label,
        render: (record: any, _index: number) => result.formatters[field.id](record[field.id]),
        sortable: field.sortable,
        sortKey: field.id
      }));
      return (
        <Box flex={{ grow: 0, shrink: 0 }}>
          {props.block.title && <Heading level="3">{props.block.title}</Heading>}
          <WaterTable columns={tableColumns} records={result.records} />
        </Box>
      );
    }}
  </GetWarehouseData>
);
