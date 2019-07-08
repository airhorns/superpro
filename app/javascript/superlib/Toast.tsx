import React from "react";
import { Grommet, Text } from "grommet";
import { ToastConsumer, ToastProvider } from "react-toast-notifications";
import { SuperproGrommetTheme } from "./SuperproTheme";

export interface ToastProps {
  appearance: "success" | "error" | "warning" | "info";
  children?: React.ReactNode;
  autoDismiss?: boolean;
  autoDismissTimeout?: number;
  onDismiss?: (e: any) => void;
  pauseOnHover?: boolean;
  placement?: "bottom-left" | "bottom-center" | "bottom-right" | "top-left" | "top-center" | "top-right";
}

export type ToastAdd = (message: React.ReactNode, options?: ToastProps, callback?: (id: number) => void) => void;
export type ToastShortcut = (message: React.ReactNode) => void;
// react-toast-notifications is a well behaved library and doesn't use imperative toasting. Good for it! It's way more convienient, so this is a wrapper
// that lets us toast imperatively.
export const toast: {
  _toast: any;
  add: ToastAdd;
  remove: (id: number, callback?: () => void) => void;
  removeAll: (callback?: () => void) => void;
  success: ToastShortcut;
  info: ToastShortcut;
  error: ToastShortcut;
  warning: ToastShortcut;
} = {
  _toast: {},
  add: (message, props, callback) => {
    message = <Grommet theme={SuperproGrommetTheme}>{message}</Grommet>;
    if (props && props.children) {
      props.children = <Grommet theme={SuperproGrommetTheme}>{props.children}</Grommet>;
    }

    toast._toast.add(message, props, callback);
  },
  remove: (id, callback) => toast._toast.remove(id, callback),
  removeAll: callback => toast._toast.removeAll(callback),
  error: (message: React.ReactNode) =>
    toast.add(<Text>{message}</Text>, { appearance: "error", autoDismiss: true, autoDismissTimeout: 8000 }),
  info: (message: React.ReactNode) =>
    toast.add(<Text>{message}</Text>, { appearance: "info", autoDismiss: true, autoDismissTimeout: 8000 }),
  warning: (message: React.ReactNode) =>
    toast.add(<Text>{message}</Text>, { appearance: "warning", autoDismiss: true, autoDismissTimeout: 8000 }),
  success: (message: React.ReactNode) =>
    toast.add(<Text>{message}</Text>, { appearance: "success", autoDismiss: true, autoDismissTimeout: 8000 })
};

export const ToastContainer = (props: { children: React.ReactNode }) => (
  <ToastProvider placement="top-center">
    <ToastConsumer>
      {(provider: any) => {
        toast._toast = provider;
        return props.children;
      }}
    </ToastConsumer>
  </ToastProvider>
);
