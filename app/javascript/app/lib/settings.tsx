import React from "react";
import Dinero from "dinero.js";
import { SuperproFlags } from "superlib";

export interface SettingsBag {
  accountId: number;
  baseUrl: string;
  devMode: boolean;
  cubeJs: {
    apiUrl: string;
    token: string;
  };
  reportingCurrency: {
    id: string;
    isoCode: string;
    symbol: string;
    exponent: number;
  };
  flags: SuperproFlags;
}

// eslint-disable-next-line @typescript-eslint/no-object-literal-type-assertion
export const SettingsContext = React.createContext<SettingsBag>({} as SettingsBag);
export const Settings: SettingsBag = (window as any).INJECTED_SETTINGS;

(Dinero as any).defaultCurrency = Settings.reportingCurrency.isoCode;
(Dinero as any).defaultPrecision = Settings.reportingCurrency.exponent;
