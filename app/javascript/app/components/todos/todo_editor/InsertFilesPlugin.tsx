import React from "react";
import { Box, Text, Button } from "grommet";
import isImage from "is-image";
import isUrl from "is-url";
import { Editor, Block } from "slate";
import { Plugin, EventHook, getEventTransfer, getEventRange, RenderBlockProps } from "slate-react";
import { Spin, assert } from "superlib";
import { UploadManager, AttachmentResult, RemoteDownloadAttachmentManager } from "../../../lib/UploadManager";
import { AttachmentContainerEnum } from "app/app-graph";
import { FormClose } from "app/components/common/SuperproIcons";

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

type TransferHandler = (
  event: Event,
  editor: Editor,
  next: () => any,
  transfer: ReturnType<typeof getEventTransfer>,
  range: ReturnType<typeof getEventRange>
) => void;

export const InsertFilesPlugin = (options: { attachmentContainerId: string; attachmentContainerType: AttachmentContainerEnum }): Plugin => {
  const insertPlaceholder = (editor: Editor) => {
    const block = Block.create({
      type: "file-placeholder",
      data: { loaded: 0, total: 100 }
    });
    editor.insertBlock(block);
    return block;
  };

  const markPlaceholderAsFailed = (editor: Editor, placeholder: Block) => {
    editor.withoutSaving(() => {
      editor.setNodeByKey(placeholder.key, {
        data: placeholder.data.set("error", true)
      } as any);
    });
  };

  const uploadToPlaceholderNode = (editor: Editor, file: File, placeholder: Block) => {
    const manager = new UploadManager(file, options.attachmentContainerType, options.attachmentContainerId, (loaded, total) => {
      editor.withoutSaving(() => {
        editor.setNodeByKey(placeholder.key, {
          data: assert(editor.value.document.getNode(placeholder.key) as Block).data.merge({ loaded, total })
        } as any);
      });
    });

    manager.run((error, attachment) => {
      editor.withoutSaving(() => {
        if (error || !attachment) {
          return markPlaceholderAsFailed(editor, placeholder);
        }
        const path = editor.value.document.getPath(placeholder.key);
        editor.removeNodeByKey(placeholder.key).insertNodeByPath(path, 0, blockForAttachment(attachment));
      });
    });
  };

  const attachFromRemoteUrl = (editor: Editor, url: string) => {
    const placeholder = insertPlaceholder(editor);
    const manager = new RemoteDownloadAttachmentManager(options.attachmentContainerType, options.attachmentContainerId);
    manager.run(url, (error, attachment) => {
      editor.withoutSaving(() => {
        if (error || !attachment) {
          return markPlaceholderAsFailed(editor, placeholder);
        }
        const path = editor.value.document.getPath(placeholder.key);
        editor.removeNodeByKey(placeholder.key).insertNodeByPath(path, 0, blockForAttachment(attachment));
      });
    });
  };

  const onInsertFiles: TransferHandler = (event, editor, next, transfer, range) => {
    const files: File[] = (transfer as any).files;
    for (const file of files) {
      if (range) {
        editor.select(range);
      }

      uploadToPlaceholderNode(editor, file, insertPlaceholder(editor));
    }
  };

  const onInsertHtml: TransferHandler = (event, editor, next, transfer, _range) => {
    const html: string = (transfer as any).html;
    const parser = new DOMParser();
    const doc = parser.parseFromString(html, "text/html");
    const body = doc.body;
    const firstChild = body.firstChild;
    if (!firstChild || firstChild.nodeName.toLowerCase() != "img") return next();
    const src = (firstChild as HTMLImageElement).src;
    attachFromRemoteUrl(editor, src);
  };

  const onInsertText: TransferHandler = (event, editor, next, transfer, _range) => {
    const text: string = (transfer as any).text;
    if (!isUrl(text)) return next();
    if (!isImage(text)) return next();
    attachFromRemoteUrl(editor, text);
  };

  const onInsert: EventHook = (event, editor, next) => {
    const transfer = getEventTransfer(event);
    const range = getEventRange(event, editor);

    switch (transfer.type) {
      case "files":
        return onInsertFiles(event, editor, next, transfer, range);
      case "html":
        return onInsertHtml(event, editor, next, transfer, range);
      case "text":
        return onInsertText(event, editor, next, transfer, range);
      default:
        return next();
    }
  };

  return {
    onDrop: onInsert,
    onPaste: onInsert,
    renderBlock(props, _editor, next) {
      switch (props.node.type) {
        case "file-placeholder":
          return <FilePlaceholder {...props} />;
        default:
          return next();
      }
    }
  };
};
