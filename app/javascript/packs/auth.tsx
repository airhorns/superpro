import "../flurishlib/polyfills";
import * as React from "react";
import * as ReactDOM from "react-dom";
import { App } from "../auth/App";

ReactDOM.render(<App />, document.body.appendChild(document.createElement("div")));
