import React from "react";
import { Plugin, RenderBlockProps } from "slate-react";
import styled from "styled-components";
import { CheckBox } from "grommet";

const CheckboxContainer = styled.div`
  display: flex;
  flex-direction: row;
  align-items: center;
  ${props => `
    margin: ${props.theme.global.size["xsmall"]};
    & + & {
      margin-top: 0em;
    }
  `}
`;

const CheckboxLabel = styled.span<{ checked: boolean }>`
  flex: 1;
  ${props => `
    opacity: ${props.checked ? 0.666 : 1};
  `}

  &:focus {
    outline: none;
  }
`;

export class CheckListItem extends React.Component<RenderBlockProps> {
  onChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const checked = event.target.checked;
    const { editor, node } = this.props;
    editor.setNodeByKey(node.key, { data: { checked } } as any);
  };

  render() {
    const checked = this.props.node.data.get("checked");
    return (
      <CheckboxContainer {...this.props.attributes}>
        <span contentEditable={false} style={{ marginRight: "1em" }}>
          <CheckBox checked={checked} onChange={this.onChange} />
        </span>
        <CheckboxLabel checked={checked} contentEditable={!this.props.readOnly} suppressContentEditableWarning>
          {this.props.children}
        </CheckboxLabel>
      </CheckboxContainer>
    );
  }
}

export const ChecklistPlugin = (_options?: {}): Plugin => {
  return {
    renderBlock(props, editor, next) {
      switch (props.node.type) {
        case "check-list-item":
          return <CheckListItem {...props} />;
        default:
          return next();
      }
    },
    onKeyDown(event, editor, next) {
      const { value } = editor;
      const key = (event as any).key;

      if (key === "Enter" && value.startBlock.type === "check-list-item") {
        editor.splitBlock().setBlocks({ data: { checked: false } } as any);
        return;
      }

      if (
        key === "Backspace" &&
        value.selection.isCollapsed &&
        value.startBlock.type === "check-list-item" &&
        value.selection.start.offset === 0
      ) {
        editor.setBlocks("paragraph");
        return;
      }

      next();
    }
  };
};
