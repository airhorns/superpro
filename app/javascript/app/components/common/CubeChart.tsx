import React from "react";
import { Box } from "grommet";
import { ResponsiveContainer } from "recharts";
import { PageLoadSpin } from "flurishlib";
import { CubeQuery } from "../../lib/cubejs";
import useBus from "use-bus";

export interface CubeChartProps {
  query: any;
  height: number;
  refreshKey: string;
  children: (result: any) => React.ReactNode;
}

export const CubeChart = (props: CubeChartProps) => {
  let refresher: (() => void) | null = null;
  useBus(props.refreshKey, () => refresher && refresher(), []);

  return (
    <CubeQuery query={props.query}>
      {({ resultSet, refresh }) => {
        refresher = refresh;
        let content: React.ReactNode;
        if (resultSet) {
          content = props.children(resultSet);
        } else {
          content = <PageLoadSpin />;
        }

        return (
          <Box>
            <ResponsiveContainer width="100%" height={300}>
              {content}
            </ResponsiveContainer>
          </Box>
        );
      }}
    </CubeQuery>
  );
};
