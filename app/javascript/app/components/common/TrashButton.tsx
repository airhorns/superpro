import React from "react";
import { omit, capitalize } from "lodash";
import { Button, ButtonProps } from "grommet";
import { Trash } from "./SuperproIcons";
import { IconProps } from "grommet-icons";
import { toast } from "superlib";
import { MutationProps } from "react-apollo";

export type TrashButtonProps = ButtonProps & { size?: IconProps["size"] };
export const TrashButton = (props: TrashButtonProps) => (
  <Button {...omit(props, ["size"])} hoverIndicator plain={false} color="status-critical" icon={<Trash size={props.size} />} />
);

export interface MutationTrashButtonProps<P extends Omit<MutationProps<any, any>, "mutation">> extends TrashButtonProps {
  mutationComponent: React.ComponentType<P>;
  mutationProps: Omit<P, "children">;
  resourceName: string;
}

export const MutationTrashButton = <P extends Omit<MutationProps<any, any>, "mutation">>(props: MutationTrashButtonProps<P>) => {
  const Component = props.mutationComponent;
  return (
    <Component {...(props.mutationProps as any)}>
      {(mutate, result) => (
        <TrashButton
          disabled={result.loading}
          onClick={async () => {
            let result;
            try {
              result = await mutate();
            } catch (e) {}

            if (result && result.data && !result.data.errors) {
              return toast.success(`${capitalize(props.resourceName)} trashed successfully.`);
            }

            toast.error(`There was an error trashing this ${props.resourceName}. Please try again.`);
          }}
        />
      )}
    </Component>
  );
};
