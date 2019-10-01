import React from "react";
import { Page } from "../common";
import { GetWarehouseData } from "../superviz/components/GetWarehouseData";
import { Box, TableCell, Heading } from "grommet";
import { StyledDataTable, StyledDataTableHeader, StyledDataTableRow, StyledDataTableBody } from "superlib/WaterTable/StyledDataTable";
import { range, keyBy, get, round } from "lodash";
import { isUndefined } from "util";

const RFMBreakdownQuery = {
  measures: [
    { model: "Customers::RFMThresholdFacts", field: "recency_threshold", id: "recency_threshold" },
    { model: "Customers::RFMThresholdFacts", field: "frequency_threshold", id: "frequency_threshold" },
    { model: "Customers::RFMThresholdFacts", field: "monetary_threshold", id: "monetary_threshold" }
  ],
  dimensions: [
    { model: "Customers::RFMThresholdFacts", field: "recency_quintile", id: "recency_quintile" },
    { model: "Customers::RFMThresholdFacts", field: "frequency_quintile", id: "frequency_quintile" },
    { model: "Customers::RFMThresholdFacts", field: "monetary_quintile", id: "monetary_quintile" },
    { model: "Customers::RFMThresholdFacts", field: "business_line", id: "business_line" }
  ]
};

const recordIndexKey = (r: number, f: number, m: number) => `${r}/${f}/${m}`;

export const RFMBreakdownTable = (props: { recordIndex: { [key: string]: any }; measureKey: string; format: (val: number) => string }) => (
  <Box flex={{ grow: 0, shrink: 0 }}>
    <StyledDataTable>
      <StyledDataTableHeader>
        <StyledDataTableRow>
          <TableCell colSpan={2}></TableCell>
          <TableCell colSpan={5}>Recency</TableCell>
        </StyledDataTableRow>
        <StyledDataTableRow>
          <TableCell>Monetary</TableCell>
          <TableCell>Frequency</TableCell>
          <TableCell>1</TableCell>
          <TableCell>2</TableCell>
          <TableCell>3</TableCell>
          <TableCell>4</TableCell>
          <TableCell>5</TableCell>
        </StyledDataTableRow>
      </StyledDataTableHeader>
      <StyledDataTableBody>
        {range(1, 6).map(monetary => (
          <>
            {range(1, 6).map(frequency => (
              <StyledDataTableRow key={frequency}>
                <TableCell>{frequency == 1 && `M=${monetary}`}</TableCell>
                <TableCell>F={frequency}</TableCell>
                {range(1, 6).map(recency => {
                  const val: number = get(props.recordIndex[recordIndexKey(recency, frequency, monetary)], props.measureKey);
                  const formattedVal = isUndefined(val) ? "-" : props.format(val);
                  return (
                    <>
                      <TableCell>{formattedVal}</TableCell>
                    </>
                  );
                })}
              </StyledDataTableRow>
            ))}
          </>
        ))}
      </StyledDataTableBody>
    </StyledDataTable>
  </Box>
);

export default () => {
  return (
    <Page.Layout title="RFM Breakdown">
      <GetWarehouseData query={RFMBreakdownQuery}>
        {result => {
          const recordIndex = keyBy(result.records, record =>
            recordIndexKey(record.recency_quintile, record.frequency_quintile, record.monetary_quintile)
          );
          return (
            <Box gap="medium">
              <Heading level="3">Monetary Thresholds by RFM tier</Heading>
              <RFMBreakdownTable recordIndex={recordIndex} measureKey="monetary_threshold" format={(val: number) => `$${round(val, 2)}`} />
              <Heading level="3">Frequency Thresholds by RFM tier</Heading>
              <RFMBreakdownTable
                recordIndex={recordIndex}
                measureKey="frequency_threshold"
                format={(val: number) => String(round(val, 2))}
              />
            </Box>
          );
        }}
      </GetWarehouseData>
    </Page.Layout>
  );
};
