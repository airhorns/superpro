import _ from "lodash";

export interface InputConfigProps {
  showErrorMessages?: boolean;
}

export const propsForGrommetComponent = (props: any) => _.omit(props, ["validate", "name", "showErrorMessages"]);
