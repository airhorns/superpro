import { FlurishFlags } from "flurishlib";

export interface SettingsBag {
  baseUrl: string;
  signedIn: boolean;
  devMode: boolean;
  flags: FlurishFlags;
}

export const Settings: SettingsBag = (window as any).INJECTED_SETTINGS;
