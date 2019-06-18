import React from "react";
import { isUndefined } from "lodash";

const Settings = (window as any).INJECTED_SETTINGS;

export const SegmentIdentify = (props: { children: React.ReactNode }) => {
  React.useEffect(() => {
    if (!isUndefined(Settings.analytics.identify)) {
      analytics.identify(Settings.analytics.identify, Settings.analytics.identifyTraits);
    }

    if (!isUndefined(Settings.analytics.group)) {
      analytics.group(Settings.analytics.group, Settings.analytics.groupTraits);
    }
  }, []);

  return props.children as any;
};
