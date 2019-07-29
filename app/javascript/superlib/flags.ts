import createFlags from "flag";

export interface SuperproFlags {
  "feature.connections": boolean;
  "feature.todos": boolean;
  "feature.budgets": boolean;
  "gate.publicSignUps": boolean;
}

const { FlagsProvider, Flag, useFlag, useFlags } = createFlags<SuperproFlags>();
export { FlagsProvider, Flag, useFlag, useFlags };
