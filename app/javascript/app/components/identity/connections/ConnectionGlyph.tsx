import React from "react";
import { Box, Image, BoxProps } from "grommet";
import { omit } from "lodash";
import ShopifyGlyph from "images/glyphs/shopify.svg";
import FacebookGlyph from "images/glyphs/facebook.png";
import GoogleAnalyticsGlyph from "images/glyphs/google-analytics.svg";
import GoogleAdsGlyph from "images/glyphs/google-ads.svg";
import KlaviyoGlyph from "images/glyphs/klaviyo.svg";
import BrontoGlyph from "images/glyphs/bronto.png";
import { Connect } from "grommet-icons";
import { ConnectionIntegrationUnion } from "app/app-graph";

export interface ConnectionGlyphProps extends BoxProps {
  typename?: ConnectionIntegrationUnion["__typename"] | "klaviyo" | "google-ads" | "bronto";
  size?: string;
}

export const ConnectionGlyph = (props: ConnectionGlyphProps) => {
  let image: React.ReactNode;
  const size = props.size || "xxsmall";

  switch (props.typename) {
    case "ShopifyShop": {
      image = <Image src={ShopifyGlyph} fit="contain" />;
      break;
    }
    case "FacebookAdAccount": {
      image = <Image src={FacebookGlyph} fit="contain" />;
      break;
    }
    case "GoogleAnalyticsCredential": {
      image = <Image src={GoogleAnalyticsGlyph} fit="contain" />;
      break;
    }
    case "klaviyo": {
      image = <Image src={KlaviyoGlyph} fit="contain" />;
      break;
    }
    case "google-ads": {
      image = <Image src={GoogleAdsGlyph} fit="contain" />;
      break;
    }
    case "bronto": {
      image = <Image src={BrontoGlyph} fit="contain" />;
      break;
    }
    default: {
      image = <Connect size={size} />;
    }
  }

  return (
    <Box width={size} height={size} {...omit(props, ["connection"])}>
      {image}
    </Box>
  );
};
