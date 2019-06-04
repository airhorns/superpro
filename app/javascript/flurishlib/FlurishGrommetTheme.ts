import { createGlobalStyle } from "styled-components";

export const FlurishGrommetTheme = {
  global: {
    font: {
      family:
        '-apple-system, BlinkMacSystemFont, "Segoe UI", "PingFang SC", "Hiragino Sans GB", "Microsoft YaHei", "Helvetica Neue", Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol";'
    }
  }
};

export const FlurishGlobalStyle = createGlobalStyle`
*, *::before, *::after {
  box-sizing: border-box;
}
h1, h2, h3, h4, h5, h6 {
  margin-block-start: 0px;
  margin-block-end: 0px;
}
`;
