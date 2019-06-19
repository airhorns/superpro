import createFlags, { Computable } from "flag";

export interface FlurishFlags {
  features: {
    connections: boolean;
  };
  publicSignUps: boolean;
}

const { FlagsProvider, Flag, useFlag, useFlags } = createFlags<FlurishFlags>();

export { FlagsProvider, Flag, useFlag, useFlags };

export const flags: Computable<FlurishFlags> = {
  features: {
    connections: false
  },
  publicSignUps: true
};
