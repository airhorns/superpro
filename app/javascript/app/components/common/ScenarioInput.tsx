import React from "react";
import { sortBy, some, capitalize, pickBy, isUndefined, isNull } from "lodash";
import { Box, Button, DropButton, Text } from "grommet";
import { controlBorderStyle } from "grommet/utils/styles";
import { DocType, useSuperForm, NumberInputProps, NumberInput, pathToName } from "superlib/superform";
import { Row } from "superlib";
import styled from "styled-components";
import { FormClose } from "./SuperproIcons";
import { ScenarioButton } from "./ScenarioButton";

const ControlRow = styled(Row)<{ plain?: boolean }>`
  ${props => !props.plain && controlBorderStyle};
`;

const ScenarioSortOrders: { [key: string]: number } = {
  optimistic: 0,
  default: 1,
  pessimistic: 2
};

export const labelForScenario = (key: string) => {
  switch (key) {
    case "optimistic":
      return "☀️";
    case "pessimistic":
      return "🌧";
    case "default":
      return "🌤";
  }
  return capitalize(key);
};

export const backgroundForScenario = (key: string) => {
  switch (key) {
    case "optimistic":
      return "#fffecc";
    case "pessimistic":
      return "#deeffc";
  }
  return "";
};

interface Scenario {
  key: string;
  value: number;
  label: string;
}

const AvailableScenarios = ["optimistic", "default", "pessimistic"].map(key => ({ key, label: labelForScenario(key) }));

export const ScenarioInputRowInput = <T extends DocType>(props: { inputProps: NumberInputProps; label: string; path: string }) => {
  const form = useSuperForm<T>();
  const id = pathToName(props.path);

  return (
    <Row gap="small">
      <label htmlFor={id}>
        <Text size="xlarge">{props.label}</Text>
      </label>
      <NumberInput {...props.inputProps} path={props.path} />
      <Button
        onClick={() => {
          form.deletePath(props.path);
        }}
        icon={<FormClose />}
      />
    </Row>
  );
};

export const ScenarioInput = <T extends DocType>(props: NumberInputProps) => {
  const form = useSuperForm<T>();
  const [open, setOpen] = React.useState(false);
  const dropRef = React.useRef<HTMLDivElement>();

  const currentValues = pickBy(form.getValue(props.path), (value, _key) => !isNull(value) && !isUndefined(value));
  const scenariosEnabled = some(Object.keys(currentValues), key => key != "default");
  let scenarios: Scenario[] = Object.entries<number>(currentValues).map(([key, value]) => ({
    key,
    value,
    label: labelForScenario(key)
  }));
  scenarios = sortBy(scenarios, scenario => ScenarioSortOrders[scenario.key] || 100);

  return (
    <ControlRow ref={dropRef} plain={props.plain}>
      <Box direction="row" flex basis="auto">
        {!scenariosEnabled && <NumberInput {...props} plain path={props.path + ".default"} />}
        {scenariosEnabled && (
          <Row gap="small" pad={{ left: "small" }}>
            {scenarios.map(scenario => (
              <Box key={scenario.key} pad="xsmall" round="xsmall" style={{ backgroundColor: backgroundForScenario(scenario.key) }}>
                <NumberInput {...{ ...props, path: props.path + "." + scenario.key }} displayType={"text"} />
              </Box>
            ))}
          </Row>
        )}
      </Box>
      <DropButton
        disabled={props.disabled}
        open={open}
        onOpen={() => setOpen(true)}
        onClose={() => setOpen(false)}
        dropContent={
          <Box pad="small" gap="small">
            {AvailableScenarios.map(scenario => (
              <ScenarioInputRowInput key={scenario.key} label={scenario.label} path={props.path + "." + scenario.key} inputProps={props} />
            ))}
          </Box>
        }
        dropTarget={dropRef.current || undefined}
      >
        <Box margin={{ horizontal: "xsmall" }} flex={false} style={{ minWidth: "auto" }}>
          <ScenarioButton enabled={scenariosEnabled} size="large" />
        </Box>
      </DropButton>
    </ControlRow>
  );
};
