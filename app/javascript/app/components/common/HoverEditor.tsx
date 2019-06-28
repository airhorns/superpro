import React from "react";
import { TextInput } from "grommet";
import { EditButton, FadeBox } from ".";
import { isTouchDevice, Row } from "flurishlib";

export interface HoverEditorProps {
  value: string;
  onChange: (event: React.ChangeEvent<HTMLInputElement>) => void;
}

export const HoverEditor = (props: HoverEditorProps) => {
  const [editing, setEditing] = React.useState(false);
  const [hovered, setHovered] = React.useState(false);

  return (
    <Row gap="small" onMouseEnter={() => setHovered(true)} onMouseLeave={() => setHovered(false)}>
      {(editing && <TextInput onChange={props.onChange} value={props.value} onBlur={() => setEditing(false)} />) || props.value}
      <FadeBox visible={isTouchDevice() || hovered}>
        <EditButton onClick={() => setEditing(!editing)} />
      </FadeBox>
    </Row>
  );
};
