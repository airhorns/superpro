export interface SettingsBag {
  baseUrl: string;
  signedIn: boolean;
  devMode: boolean;
}

export const Settings: SettingsBag = (window as any).INJECTED_SETTINGS;
