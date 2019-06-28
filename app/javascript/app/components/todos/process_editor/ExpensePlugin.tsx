import React from "react";
import { Plugin, RenderBlockProps } from "slate-react";
import NumberFormat from "react-number-format";
import styled from "styled-components";
import { Button } from "grommet";
import { Row } from "flurishlib";
import { Expense } from "app/components/common/FlurishIcons";
import { isAuthoringMode } from "./utils";

const ExpenseContainer = styled.div`
  display: flex;
  flex-direction: row;
  align-items: center;
  ${props => `
    margin: ${props.theme.global.edgeSize["small"]};
    & + & {
      margin-top: 0em;
    }
  `}
`;

const ExpenseLabel = styled.span<{ incurred: boolean }>`
  flex: 1;
  ${props => `
    opacity: ${props.incurred ? 0.666 : 1};
    text-decoration: ${props.incurred ? "strikethrough" : "none"};
  `}

  &:focus {
    outline: none;
  }
`;

export class ExpenseItem extends React.Component<RenderBlockProps> {
  onChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const checked = event.target.checked;
    const { editor, node } = this.props;
    editor.setNodeByKey(node.key, { data: { checked } } as any);
  };

  render() {
    const checked = this.props.node.data.get("checked");
    return (
      <ExpenseContainer {...this.props.attributes}>
        <Row contentEditable={false} margin={{ right: "small" }} gap="xsmall">
          <Expense />
          <NumberFormat
            prefix={"$"}
            fixedDecimalScale
            decimalScale={2}
            value={this.props.node.data.get("amount") || 0}
            displayType={"text"}
          />
        </Row>
        <ExpenseLabel incurred={checked} contentEditable={!this.props.readOnly} suppressContentEditableWarning>
          {this.props.children}
        </ExpenseLabel>
        <Button plain onClick={() => {}} disabled={isAuthoringMode(this.props.editor)} label="Mark as incurred" />
      </ExpenseContainer>
    );
  }
}

export const ExpensePlugin = (_options?: {}): Plugin => {
  return {
    renderBlock(props, editor, next) {
      switch (props.node.type) {
        case "expense-item":
          return <ExpenseItem {...props} />;
        default:
          return next();
      }
    },
    onKeyDown(event, editor, next) {
      const { value } = editor;
      const key = (event as any).key;

      if (key === "Enter" && value.startBlock.type === "expense-item") {
        // On starting a new line with the enter key, add a new block of the same type that isn't checked below by splitting the current block
        if (value.startText.text.length > 0) {
          editor.splitBlock().setBlocks({ data: { incurred: false, amountSubunits: 0 } } as any);
        } else {
          editor.setBlocks("paragraph");
        }
        return;
      }

      if (
        key === "Backspace" &&
        value.selection.isCollapsed &&
        value.startBlock.type === "expense-item" &&
        value.selection.start.offset === 0
      ) {
        editor.setBlocks("paragraph");
        return;
      }

      next();
    }
  };
};
