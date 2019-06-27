import createFlags from "flag";

export interface FlurishFlags {
  "feature.connections": boolean;
  "feature.tasks": boolean;
  "gate.publicSignUps": boolean;
}

const { FlagsProvider, Flag, useFlag, useFlags } = createFlags<FlurishFlags>();
export { FlagsProvider, Flag, useFlag, useFlags };
