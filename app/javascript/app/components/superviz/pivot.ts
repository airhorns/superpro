import { VizBlock } from ".";
import { VizSystem } from "./schema";
import { assert } from "superlib";

export const pivotGroupId = (system: VizSystem) => `${system.yId}:::${assert(system.segmentIds).join(":")}`;

export interface WarehousePivot {
  id: string;
  measure_ids: string[];
  pivot_field_ids: string[];
}

export const pivotForViz = (block: VizBlock): WarehousePivot | undefined => {
  const systemsRequiringPivot = block.viz.systems.filter(system => system.segmentIds && system.segmentIds.length > 0);
  if (systemsRequiringPivot.length == 0) {
    return undefined;
  } else if (systemsRequiringPivot.length > 1) {
    throw "Can't pivot more than one system simultaneously right now";
  }

  const system = systemsRequiringPivot[0];
  return {
    id: pivotGroupId(system),
    measure_ids: [system.yId],
    pivot_field_ids: assert(system.segmentIds)
  };
};
