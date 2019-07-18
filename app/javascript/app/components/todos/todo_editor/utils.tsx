import React from "react";
import { Editor, Block } from "slate";
import { Editor as ReactEditor, RenderBlockProps } from "slate-react";
import { Button, Box, Text } from "grommet";
import { assert, Spin } from "superlib";
import { AttachmentContainerEnum } from "app/app-graph";
import { UploadManager, AttachmentResult, RemoteDownloadAttachmentManager } from "app/lib/UploadManager";
import { FormClose } from "app/components/common/SuperproIcons";

export const isTemplateMode = (editor: Editor | ReactEditor) => editor.value.data.get("mode") === "template";
export const isExecutionMode = (editor: Editor | ReactEditor) => editor.value.data.get("mode") === "execution";
export const isFullEditingMode = (editor: Editor | ReactEditor) =>
  editor.value.data.get("mode") === "execution" || editor.value.data.get("mode") === "scratchpad";
export const isScratchpadMode = (editor: Editor | ReactEditor) => editor.value.data.get("mode") === "scratchpad";

export const blockForAttachment = (attachment: AttachmentResult) => {
  const attrs = {
    data: attachment
  } as any;

  if (attachment.contentType.startsWith("image")) {
    attrs.type = "image";
  } else {
    attrs.type = "file-attachment";
  }

  return Block.create(attrs);
};

export const FilePlaceholder = (props: RenderBlockProps) => {
  const error = props.node.data.get("error");
  return (
    <Box
      pad="small"
      {...props.attributes}
      background="light-1"
      border={{ color: props.isSelected ? "focus" : "light-3", side: "all" }}
      flex={false}
      width="auto"
      align="center"
      justify="center"
    >
      {!error && <Spin />}
      {error && (
        <Box gap="small" align="center">
          <Text color="status-critical">There was an error uploading this file. Please try again.</Text>
          <Button icon={<FormClose />} label="Dismiss" onClick={() => props.editor.removeNodeByKey(props.node.key)} />
        </Box>
      )}
    </Box>
  );
};

export const insertFilePlaceholder = (editor: Editor | ReactEditor) => {
  const block = Block.create({
    type: "file-placeholder",
    data: { loaded: 0, total: 100 }
  });
  editor.insertBlock(block);
  return block;
};

export const markFilePlaceholderAsFailed = (editor: Editor | ReactEditor, placeholder: Block) => {
  editor.withoutSaving(() => {
    editor.setNodeByKey(placeholder.key, {
      data: placeholder.data.set("error", true)
    } as any);
  });
};

export const uploadToPlaceholderNode = (
  editor: Editor | ReactEditor,
  file: File,
  placeholder: Block,
  attachmentContainerId: string,
  attachmentContainerType: AttachmentContainerEnum
) => {
  const manager = new UploadManager(file, attachmentContainerType, attachmentContainerId, (loaded, total) => {
    editor.withoutSaving(() => {
      editor.setNodeByKey(placeholder.key, {
        data: assert(editor.value.document.getNode(placeholder.key) as Block).data.merge({ loaded, total })
      } as any);
    });
  });

  manager.run((error, attachment) => {
    editor.withoutSaving(() => {
      if (error || !attachment) {
        return markFilePlaceholderAsFailed(editor, placeholder);
      }
      const path = editor.value.document.getPath(placeholder.key);
      editor.removeNodeByKey(placeholder.key).insertNodeByPath(path, 0, blockForAttachment(attachment));
    });
  });
};

export const attachFromRemoteUrl = (
  editor: Editor | ReactEditor,
  url: string,
  attachmentContainerId: string,
  attachmentContainerType: AttachmentContainerEnum
) => {
  const placeholder = insertFilePlaceholder(editor);
  const manager = new RemoteDownloadAttachmentManager(attachmentContainerType, attachmentContainerId);
  manager.run(url, (error, attachment) => {
    editor.withoutSaving(() => {
      if (error || !attachment) {
        return markFilePlaceholderAsFailed(editor, placeholder);
      }
      const path = editor.value.document.getPath(placeholder.key);
      editor.removeNodeByKey(placeholder.key).insertNodeByPath(path, 0, blockForAttachment(attachment));
    });
  });
};
