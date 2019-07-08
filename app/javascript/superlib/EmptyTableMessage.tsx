import React from "react";
import { Box, Text, TableCell } from "grommet";

export const EmptyTableMessage = (props: { message: React.ReactNode; colSpan: number }) => (
  <TableCell scope="row" colSpan={props.colSpan}>
    <Box pad="small" justify="center" align="center" fill>
      <Text color="status-unknown">{props.message}</Text>
    </Box>
  </TableCell>
);
