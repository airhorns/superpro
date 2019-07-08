import React from "react";
import { Row } from "superlib";
import { range } from "lodash";
import memoizeOne from "memoize-one";
import { Box, Text } from "grommet";
import { DateTime } from "luxon";
import { NumberInput } from "superlib/superform";

const DefaultCellMonths = memoizeOne(() => {
  const now = DateTime.local();
  const currentYear = now.year;
  const currentMonth = now.month;
  return range(0, 12).map(i => DateTime.local(currentYear, currentMonth, 1).plus({ months: i }));
});

export const BudgetLineSeriesCells = (props: { path: string }) => {
  return (
    <Row overflow={{ horizontal: "auto" }}>
      {DefaultCellMonths().map((dateTime, index) => (
        <Box key={index} width="150px" flex={false}>
          <Text>{dateTime.toFormat("MMM yy")}</Text>
          <NumberInput
            plain
            path={`${props.path}.cells.${dateTime.valueOf()}.amountScenarios.default`}
            prefix={"$"}
            fixedDecimalScale
            decimalScale={2}
            storeAsSubunits
            placeholder="Month amount"
          />
        </Box>
      ))}
    </Row>
  );
};
