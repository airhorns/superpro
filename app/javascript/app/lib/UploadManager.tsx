import { DirectUpload, Blob as ResponseBlob } from "activestorage";
import gql from "graphql-tag";
import { Settings } from "./settings";
import {
  AttachUploadToContainerDocument,
  AttachUploadToContainerMutation,
  AttachmentContainerEnum,
  AttachRemoteUrlToContainerDocument
} from "app/app-graph";
import { SuperproClient } from "app/App";

gql`
  mutation AttachUploadToContainer(
    $directUploadSignedId: String!
    $attachmentContainerId: ID!
    $attachmentContainerType: AttachmentContainerEnum!
  ) {
    attachDirectUploadedFile(
      directUploadSignedId: $directUploadSignedId
      attachmentContainerId: $attachmentContainerId
      attachmentContainerType: $attachmentContainerType
    ) {
      attachment {
        id
        filename
        contentType
        bytesize
        url
      }
      errors
    }
  }

  mutation AttachRemoteUrlToContainer($url: String!, $attachmentContainerId: ID!, $attachmentContainerType: AttachmentContainerEnum!) {
    attachRemoteUrl(url: $url, attachmentContainerId: $attachmentContainerId, attachmentContainerType: $attachmentContainerType) {
      attachment {
        id
        filename
        contentType
        bytesize
        url
      }
      errors
    }
  }
`;

export type ProgressCallback = (loaded: number, total: number) => void;
export type AttachmentResult = Exclude<Exclude<AttachUploadToContainerMutation["attachDirectUploadedFile"], null>["attachment"], null>;

export class UploadManager {
  upload: DirectUpload;
  containerType: AttachmentContainerEnum;
  containerId: string;
  onProgress?: ProgressCallback;

  constructor(file: File, containerType: AttachmentContainerEnum, containerId: string, onProgress?: ProgressCallback) {
    this.onProgress = onProgress;
    this.containerType = containerType;
    this.containerId = containerId;
    this.upload = new DirectUpload(file, Settings.directUploadUrl, this);
  }

  run(callback: (error?: Error, attachment?: AttachmentResult) => void) {
    this.upload.create((error: Error, response: ResponseBlob) => {
      if (error) {
        return callback(error, undefined);
      } else {
        SuperproClient.mutate({
          mutation: AttachUploadToContainerDocument,
          variables: {
            directUploadSignedId: response.signed_id,
            attachmentContainerId: this.containerId,
            attachmentContainerType: this.containerType
          }
        })
          .then(result => {
            if (result.errors) {
              return callback(result.errors[0], undefined);
            }
            callback(undefined, result.data.attachDirectUploadedFile.attachment);
          })
          .catch(reason => callback(reason));
      }
    });
  }

  directUploadWillStoreFileWithXHR(request: XMLHttpRequest) {
    request.upload.addEventListener("progress", event => {
      this.onProgress && this.onProgress(event.loaded, event.total);
    });
  }
}

export class RemoteDownloadAttachmentManager {
  containerType: AttachmentContainerEnum;
  containerId: string;

  constructor(containerType: AttachmentContainerEnum, containerId: string) {
    this.containerType = containerType;
    this.containerId = containerId;
  }

  run(url: string, callback: (error?: Error, attachment?: AttachmentResult) => void) {
    SuperproClient.mutate({
      mutation: AttachRemoteUrlToContainerDocument,
      variables: {
        url: url,
        attachmentContainerId: this.containerId,
        attachmentContainerType: this.containerType
      }
    })
      .then(result => {
        if (result.errors) {
          return callback(result.errors[0], undefined);
        }
        callback(undefined, result.data.attachRemoteUrl.attachment);
      })
      .catch(reason => callback(reason));
  }
}
