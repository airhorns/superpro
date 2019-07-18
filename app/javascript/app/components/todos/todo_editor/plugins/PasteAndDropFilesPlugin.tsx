import React from "react";
import isImage from "is-image";
import isUrl from "is-url";
import { Editor } from "slate";
import { Plugin, EventHook, getEventTransfer, getEventRange } from "slate-react";
import { AttachmentContainerEnum } from "app/app-graph";
import { insertFilePlaceholder, uploadToPlaceholderNode, attachFromRemoteUrl, FilePlaceholder } from "../utils";

type TransferHandler = (
  event: Event,
  editor: Editor,
  next: () => any,
  transfer: ReturnType<typeof getEventTransfer>,
  range: ReturnType<typeof getEventRange>
) => void;

export const PasteAndDropFilesPlugin = (options: {
  attachmentContainerId: string;
  attachmentContainerType: AttachmentContainerEnum;
}): Plugin => {
  const onInsertFiles: TransferHandler = (event, editor, next, transfer, range) => {
    const files: File[] = (transfer as any).files;
    for (const file of files) {
      if (range) {
        editor.select(range);
      }

      uploadToPlaceholderNode(editor, file, insertFilePlaceholder(editor), options.attachmentContainerId, options.attachmentContainerType);
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
    attachFromRemoteUrl(editor, src, options.attachmentContainerId, options.attachmentContainerType);
  };

  const onInsertText: TransferHandler = (event, editor, next, transfer, _range) => {
    const text: string = (transfer as any).text;
    if (!isUrl(text)) return next();
    if (!isImage(text)) return next();
    attachFromRemoteUrl(editor, text, options.attachmentContainerId, options.attachmentContainerType);
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
