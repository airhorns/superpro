import React from "react";
import gql from "graphql-tag";
import { ToolbarButton } from "./Toolbar";
import { Share } from "app/components/common/SuperproIcons";
import { GetScratchpadForSharingComponent, useSetScratchpadSharingMutation } from "app/app-graph";
import { mutationSuccess, toast, SimpleModal, SimpleQuery } from "superlib";
import { Heading, Box, Button } from "grommet";
import { SuperForm, RadioButtons } from "superlib/superform";

gql`
  query GetScratchpadForSharing($id: ID!) {
    scratchpad(id: $id) {
      id
      accessMode
    }
  }

  mutation SetScratchpadSharing($id: ID!, $attributes: ScratchpadAttributes!) {
    updateScratchpad(id: $id, attributes: $attributes) {
      scratchpad {
        id
        accessMode
      }
      errors {
        fullMessage
      }
    }
  }
`;

interface ScratchpadShareFormValues {
  scratchpad: {
    accessMode: string;
  };
}

const SharingOptions = [{ value: "PRIVATE", label: "Private" }, { value: "PUBLIC", label: "Shared with other account users" }];

export const ShareScratchpadButton = (props: { id: string }) => {
  const updateScratchpad = useSetScratchpadSharingMutation();

  const handleSubmit = React.useCallback(
    async (formValues: ScratchpadShareFormValues, setShow: (value: boolean) => void) => {
      let success = false;
      let result;
      try {
        result = await updateScratchpad({
          variables: {
            id: props.id,
            attributes: {
              accessMode: formValues.scratchpad.accessMode as any
            }
          }
        });
      } catch (e) {}

      const data = mutationSuccess(result, "updateScratchpad");
      if (data) {
        success = true;
        toast.success("Scratchpad sharing set successfully.");
        setShow(false);
      }

      if (!success) {
        toast.error("There was an error editing this scratchpad. Please try again.");
      }
    },
    [props.id, updateScratchpad]
  );

  return (
    <SimpleModal trigger={setShow => <ToolbarButton icon={Share} active={false} onClick={() => setShow(true)} />}>
      {setShow => (
        <SimpleQuery component={GetScratchpadForSharingComponent} require={["scratchpad"]} variables={{ id: props.id }}>
          {data => (
            <Box gap="medium">
              <Heading level="3">Share Scratchpad</Heading>
              <SuperForm<ScratchpadShareFormValues>
                initialValues={{ scratchpad: data.scratchpad }}
                onSubmit={formValues => handleSubmit(formValues, setShow)}
              >
                {() => (
                  <Box gap="small">
                    <RadioButtons path="scratchpad.accessMode" options={SharingOptions} />
                    <Button type="submit" label="Save Sharing" />
                  </Box>
                )}
              </SuperForm>
            </Box>
          )}
        </SimpleQuery>
      )}
    </SimpleModal>
  );
};
