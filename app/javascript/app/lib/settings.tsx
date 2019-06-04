import * as React from "react";

export interface SettingsBag {
  accountId: number;
  baseUrl: string;
  devMode: boolean;
}

// eslint-disable-next-line @typescript-eslint/no-object-literal-type-assertion
export const SettingsContext = React.createContext<SettingsBag>({} as SettingsBag);
export const Settings: SettingsBag = (window as any).INJECTED_SETTINGS;
