import echarts, { EChartOption } from "echarts/lib/echarts";

// export const colorPalette = ["#3288bd", "#f46d43", "#fee08b", "#5e4fa2", "#9e0142", "#66c2a5", "#d53e4f", "#abdda4", "#e6f598", "#fdae61"];
export const colorPalette = ["#6a3d9a", "#ff7f00", "#e31a1c", "#33a02c", "#1f78b4", "#cab2d6", "#fdbf6f", "#fb9a99", "#b2df8a", "#a6cee3"];
export const controlColor = colorPalette[0];
export const negativeColor = "#c12e34";
export const positiveColor = "#0F8554";
export const textColor = "#333";

interface EChartTheme {
  [key: string]: any;
  xAxis: Partial<EChartOption["xAxis"]>;
  yAxis: Partial<EChartOption["yAxis"]>;
}

export const theme: EChartTheme = {
  color: colorPalette,

  title: {
    textStyle: {
      fontWeight: "normal"
    }
  },

  visualMap: {
    color: ["#1790cf", "#a2d4e6"]
  },

  toolbox: {
    iconStyle: {
      normal: {
        borderColor: "#06467c"
      }
    }
  },

  tooltip: {
    backgroundColor: "rgba(0,0,0,0.6)"
  },

  dataZoom: {
    dataBackgroundColor: "#dedede",
    fillerColor: "rgba(154,217,247,0.2)",
    handleColor: controlColor
  },

  timeline: {
    lineStyle: {
      color: controlColor
    },
    controlStyle: {
      normal: {
        color: controlColor,
        borderColor: controlColor
      }
    }
  },

  candlestick: {
    itemStyle: {
      normal: {
        color: negativeColor,
        color0: positiveColor,
        lineStyle: {
          width: 1,
          color: negativeColor,
          color0: positiveColor
        }
      }
    }
  },

  graph: {
    color: colorPalette
  },

  map: {
    label: {
      normal: {
        textStyle: {
          color: negativeColor
        }
      },
      emphasis: {
        textStyle: {
          color: negativeColor
        }
      }
    },
    itemStyle: {
      normal: {
        borderColor: "#eee",
        areaColor: "#ddd"
      },
      emphasis: {
        areaColor: "#e6b600"
      }
    }
  },

  gauge: {
    axisLine: {
      show: true,
      lineStyle: {
        color: [[0.2, positiveColor], [0.8, controlColor], [1, negativeColor]],
        width: 5
      }
    },
    axisTick: {
      splitNumber: 10,
      length: 8,
      lineStyle: {
        color: "auto"
      }
    },
    axisLabel: {
      textStyle: {
        color: "auto"
      }
    },
    splitLine: {
      length: 12,
      lineStyle: {
        color: "auto"
      }
    },
    pointer: {
      length: "90%",
      width: 3,
      color: "auto"
    },
    title: {
      textStyle: {
        color: textColor
      }
    },
    detail: {
      textStyle: {
        color: "auto"
      }
    }
  },

  xAxis: {
    nameGap: 44,
    nameLocation: "center",
    axisLabel: {
      fontSize: 18
    },
    nameTextStyle: {
      color: textColor
    }
  },

  yAxis: {
    axisLabel: {
      fontSize: 18
    },
    nameTextStyle: {
      color: textColor
    }
  },

  textStyle: {
    fontSize: 18
  }
};

echarts.registerTheme("superpro", theme);
