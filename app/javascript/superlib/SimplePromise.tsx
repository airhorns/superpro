import React from "react";
import { useLoads } from "react-loads";
import { Alert } from "./Alert";
import { PageLoadSpin } from "./Spin";

export const SimplePromise = <T extends any>(props: { callback: () => Promise<T>; children: (data: T) => React.ReactNode }) => {
  const { response, isRejected, isPending, isResolved } = useLoads(props.callback);

  return (
    <>
      {isPending && <PageLoadSpin />}
      {isRejected && <Alert type="error" message="There was an error loading data. Please try again." />}
      {isResolved && response && props.children(response)}
    </>
  );
};
