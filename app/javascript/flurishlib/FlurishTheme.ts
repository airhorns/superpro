import { createGlobalStyle } from "styled-components";
import { generate } from "grommet/themes";
import { normalizeColor } from "grommet/utils";
import { lighten } from "polished";
import { merge } from "lodash";
import { Props as ReactSelectProps } from "react-select/lib/Select";

export const FlurishGrommetTheme = merge({}, generate(24), {
  global: {
    font: {
      family:
        '-apple-system, BlinkMacSystemFont, "Segoe UI", "PingFang SC", "Hiragino Sans GB", "Microsoft YaHei", "Helvetica Neue", Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol";'
    },
    input: {
      weight: "normal"
    }
  }
});

export const FlurishGlobalStyle = createGlobalStyle`
body { margin: 0; }
*, *::before, *::after {
  box-sizing: border-box;
}
h1, h2, h3, h4, h5, h6 {
  margin-block-start: 0px;
  margin-block-end: 0px;
}
`;

const ReactSelectColors = {
  primary: FlurishGrommetTheme.global.colors.brand,
  primary75: lighten(0.1, FlurishGrommetTheme.global.colors.brand),
  primary50: lighten(0.3, FlurishGrommetTheme.global.colors.brand),
  primary25: lighten(0.75, FlurishGrommetTheme.global.colors.brand),
  neutral20: normalizeColor(FlurishGrommetTheme.global.control.border.color, FlurishGrommetTheme)
};

export const FlurishReactSelectTheme: ReactSelectProps["theme"] = theme => {
  return {
    ...theme,
    colors: {
      ...theme.colors,
      ...ReactSelectColors
    },
    spacing: {
      ...theme.spacing,
      controlHeight: 45
    }
  };
};
