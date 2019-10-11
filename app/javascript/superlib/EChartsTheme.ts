import echarts, { EChartOption } from "echarts/lib/echarts";
import { SuperproGrommetTheme } from "superlib";

export const colorPalette = ["#c12e34", "#e6b600", "#0098d9", "#2b821d", "#005eaa", "#339ca8", "#cda819", "#32a487"];

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
    handleColor: "#005eaa"
  },

  timeline: {
    lineStyle: {
      color: "#005eaa"
    },
    controlStyle: {
      normal: {
        color: "#005eaa",
        borderColor: "#005eaa"
      }
    }
  },

  candlestick: {
    itemStyle: {
      normal: {
        color: "#c12e34",
        color0: "#2b821d",
        lineStyle: {
          width: 1,
          color: "#c12e34",
          color0: "#2b821d"
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
          color: "#c12e34"
        }
      },
      emphasis: {
        textStyle: {
          color: "#c12e34"
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
        color: [[0.2, "#2b821d"], [0.8, "#005eaa"], [1, "#c12e34"]],
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
        color: "#333"
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
    }
  },

  yAxis: {
    axisLabel: {
      fontSize: 18
    }
  },

  textStyle: {
    fontSize: 18
  }
};

echarts.registerTheme("superpro", theme);