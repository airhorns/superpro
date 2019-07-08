import { SuperproFlags } from "superlib";

export interface SettingsBag {
  baseUrl: string;
  signedIn: boolean;
  devMode: boolean;
  flags: SuperproFlags;
}

export const Settings: SettingsBag = (window as any).INJECTED_SETTINGS;
