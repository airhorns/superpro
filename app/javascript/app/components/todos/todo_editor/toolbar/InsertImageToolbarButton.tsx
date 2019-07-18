import React from "react";
import { Editor } from "slate-react";
import { Image } from "app/components/common/SuperproIcons";
import { SimpleModalOverlay } from "superlib";
import { Box, Heading } from "grommet";
import { ToolbarButton } from "./Toolbar";
import { useDropzone } from "react-dropzone";
import { uploadToPlaceholderNode, insertFilePlaceholder } from "../utils";
import { AttachmentContainerEnum } from "app/app-graph";

export const InsertImageToolbarButton = (props: {
  editor: Editor;
  attachmentContainerId: string;
  attachmentContainerType: AttachmentContainerEnum;
}) => {
  const [showModal, setShowModal] = React.useState(false);
  const onDrop = React.useCallback(
    acceptedFiles => {
      for (const file of acceptedFiles) {
        uploadToPlaceholderNode(
          props.editor,
          file,
          insertFilePlaceholder(props.editor),
          props.attachmentContainerId,
          props.attachmentContainerType
        );
      }
      setShowModal(false);
    },
    [props.editor, props.attachmentContainerId, props.attachmentContainerType]
  );
  const { getRootProps, getInputProps, isDragActive } = useDropzone({ onDrop });

  let focusedBlockIsImage = false;
  if (props.editor.value.selection.focus.path) {
    const focusedBlock = props.editor.value.document.getClosestBlock(props.editor.value.selection.focus.path);
    focusedBlockIsImage = !!(focusedBlock && focusedBlock.object == "block" && focusedBlock.type && focusedBlock.type == "image");
  }

  return (
    <>
      <ToolbarButton active={focusedBlockIsImage} icon={Image} onClick={() => setShowModal(true)} />
      {showModal && (
        <SimpleModalOverlay setShow={setShowModal}>
          <Box gap="small">
            <Heading level="3">Insert Image</Heading>
            <Box
              {...getRootProps()}
              align="center"
              justify="center"
              height="medium"
              width="large"
              margin="small"
              border={{ side: "all", style: "dashed" }}
            >
              <input {...getInputProps()} />
              {isDragActive ? <p>Drop the files here ...</p> : <p>Drag and drop some files here, or click to select files</p>}
            </Box>
          </Box>
        </SimpleModalOverlay>
      )}
    </>
  );
};
