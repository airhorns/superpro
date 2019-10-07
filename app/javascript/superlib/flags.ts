import createFlags from "flag";
import { KeyPath } from "useful-types";

export interface SuperproFlags {
  "gate.publicSignUps": boolean;
  "gate.productAccess": boolean;
  "feature.facebookAds": boolean;
  "feature.googleAds": boolean;
  "feature.googleAnalytics": boolean;
  "feature.klaviyo": boolean;
  "feature.bronto": boolean;
}

const { FlagsProvider, Flag, useFlag, useFlags } = createFlags<SuperproFlags>();
export { FlagsProvider, Flag, useFlag, useFlags };
export type FlagKeyPath = KeyPath<SuperproFlags>;
