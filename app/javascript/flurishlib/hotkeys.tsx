import React from "react";
export { default as Hotkeys } from "slate-hotkeys";

interface Listener {
  detector: (event: KeyboardEvent) => boolean;
  callback: (event: KeyboardEvent) => void;
}

const Listeners = new Set<Listener>();

export const dispatch = (event: KeyboardEvent) => {
  const callbacks: Listener["callback"][] = [];
  Listeners.forEach(listener => {
    if (listener.detector(event)) {
      callbacks.push(listener.callback);
    }
  });
  callbacks.forEach(callback => callback(event));
};

export const HotkeysContainer = (props: { children: React.ReactNode }) => {
  React.useEffect(() => {
    window.document.addEventListener("keydown", dispatch);
    return () => {
      window.document.removeEventListener("keydown", dispatch);
    };
  });

  return <>{props.children}</>;
};

export const Hotkey = React.memo((props: { detector: (event: KeyboardEvent) => boolean; onHotkey: (event: KeyboardEvent) => void }) => {
  const listener = React.useMemo(() => ({ detector: props.detector, callback: props.onHotkey }), [props.detector, props.onHotkey]);

  React.useEffect(() => {
    Listeners.add(listener);
    return () => {
      Listeners.delete(listener);
    };
  }, [listener]);

  return null;
});
