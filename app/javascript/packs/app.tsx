import "../flurishlib/polyfills";
import * as React from "react";
import * as ReactDOM from "react-dom";
import { SettingsBag, SettingsContext } from "../app/lib/settings";
import { App } from "../app/components/App";

ReactDOM.render(
  <SettingsContext.Provider value={(window as any).INJECTED_SETTINGS as SettingsBag}>
    <App />
  </SettingsContext.Provider>,
  document.body.appendChild(document.createElement("main"))
);
