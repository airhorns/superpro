import React from "react";
import { Box, Image, BoxProps } from "grommet";
import { omit } from "lodash";
import ShopifyGlyph from "images/glyphs/shopify.svg";
import FacebookGlyph from "images/glyphs/facebook.png";
import GoogleAnalyticsGlyph from "images/glyphs/google-analytics.svg";
import { Connect } from "grommet-icons";
import { ConnectionIntegrationUnion } from "app/app-graph";

export interface ConnectionGlyphProps extends BoxProps {
  typename?: ConnectionIntegrationUnion["__typename"];
  size?: BoxProps["width"];
}

export const ConnectionGlyph = (props: ConnectionGlyphProps) => {
  let image: React.ReactNode;
  let size = props.size || "xxsmall";

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
