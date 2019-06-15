import React from "react";
import { sortBy, some, capitalize, pick, pickBy, isUndefined, isNull } from "lodash";
import { Box, DropButton, Text } from "grommet";
import { controlBorderStyle } from "grommet/utils/styles";
import { DocType, useSuperForm, NumberInputProps, NumberInput, pathToName } from "flurishlib/superform";
import NumberFormat from "react-number-format";
import { Row } from "flurishlib";
import styled from "styled-components";

const ControlRow = styled(Row)`
  ${controlBorderStyle};
`;

const ScenarioSortOrders: { [key: string]: number } = {
  optimistic: 0,
  default: 1,
  pessimistic: 2
};

const labelForScenario = (key: string) => {
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

const backgroundForScenario = (key: string) => {
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

export const ScenarioInputRowInput = (props: { inputProps: NumberInputProps; label: string }) => {
  const inputRef = React.useRef<HTMLInputElement>();
  const id = pathToName(props.inputProps.path);

  return (
    <Row gap="small">
      <label htmlFor={id}>
        <Text size="xlarge">{props.label}</Text>
      </label>
      <NumberInput {...props.inputProps} ref={inputRef as any} />
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
    <ControlRow ref={dropRef}>
      <Box direction="row" flex basis="auto">
        {!scenariosEnabled && <NumberInput {...props} plain path={props.path + ".default"} />}
        {scenariosEnabled && (
          <Row gap="small" pad={{ left: "small" }}>
            {scenarios.map(scenario => (
              <Box key={scenario.key} pad="xsmall" round="xsmall" style={{ backgroundColor: backgroundForScenario(scenario.key) }}>
                <NumberFormat
                  {...(pick(props, ["prefix", "fixedDecimalScale", "decimalScale", "format", "storeAsSubunits"]) as any)}
                  value={scenario.value}
                  displayType={"text"}
                />
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
              <ScenarioInputRowInput
                key={scenario.key}
                label={scenario.label}
                inputProps={{ ...props, path: props.path + "." + scenario.key }}
              />
            ))}
          </Box>
        }
        dropTarget={dropRef.current || undefined}
      >
        <Box margin={{ horizontal: "xsmall" }} flex={false} style={{ minWidth: "auto" }}>
          <Text size="large" style={{ filter: scenariosEnabled ? "" : "grayscale(100%)" }}>
            🌤
          </Text>
        </Box>
      </DropButton>
    </ControlRow>
  );
};
