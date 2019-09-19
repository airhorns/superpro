import React from "react";
import { Document, TableBlock } from "../schema";
import { GetWarehouseData, VizQueryContext } from "./GetWarehouseData";
import { WaterTable } from "superlib/WaterTable";
import { Box, Heading } from "grommet";

export const TableBlockRenderer = (props: { doc: Document; block: TableBlock }) => (
  <GetWarehouseData query={props.block.query}>
    <VizQueryContext.Consumer>
      {result => {
        const tableColumns = Object.values(result.queryIntrospection.fields).map(field => ({
          key: field.id,
          header: field.label,
          render: (record: any, _index: number) => String(record[field.id]),
          sortable: field.sortable,
          sortKey: field.id
        }));
        return (
          <Box>
            {props.block.title && <Heading level="3">{props.block.title}</Heading>}
            <WaterTable columns={tableColumns} records={result.records} />
          </Box>
        );
      }}
    </VizQueryContext.Consumer>
  </GetWarehouseData>
);
