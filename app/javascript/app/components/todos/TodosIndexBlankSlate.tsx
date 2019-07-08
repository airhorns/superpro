import React from "react";
import useReactRouter from "use-react-router";

import { Text, Box, Heading, Button } from "grommet";
import { Todos, Process } from "../common/SuperproIcons";
import { Row } from "superlib";
import { createScratchpad } from "./TodosIndexPage";
import { useApolloClient } from "react-apollo-hooks";

const BlankSlateCard = (props: {
  title: string;
  destination?: string;
  onClick?: () => void;
  children?: React.ReactNode;
  icon?: React.ReactNode;
}) => {
  const { history } = useReactRouter();

  return (
    <Button
      as="div"
      onClick={() => {
        if (props.onClick) {
          props.onClick();
        } else if (props.destination) {
          history.push(props.destination);
        }
      }}
      hoverIndicator
    >
      <Box pad="small" gap="small">
        <Heading>
          <Row gap="small">
            {props.icon}
            {props.title}
          </Row>
        </Heading>
        {props.children}
      </Box>
    </Button>
  );
};

export const TodosIndexBlankSlate = () => {
  const client = useApolloClient();

  return (
    <Box flex pad="medium" gap="medium">
      <Text>Use Superpro&apos;s Todos to keep track of the stuff you have to do.</Text>
      <BlankSlateCard title="Create a Scratchpad" onClick={() => createScratchpad(client)} icon={<Todos size="large" color="brand" />}>
        <ul>
          <li>A scratchpad is a handy note to store whatever stuff you have going on that doesn&apos;t fit anywhere else.</li>
          <li>
            Stick todos, ideas in progress, lists of things to keep track of, or whatever you want really in your notes, and then share them
            when you&apos;re ready.
          </li>
        </ul>
      </BlankSlateCard>
      <BlankSlateCard title="Start a Process Doc" destination="/todos/process/docs/new" icon={<Process size="large" color="brand" />}>
        <ul>
          <li>A process is a set of instructions and to-do items for how to do something important for your business.</li>
          <li>Write down how to conduct the process, set deadlines, and assign pieces of it to whoever needs to get it done.</li>
          <li>Processes can be easily repeated or scheduled so they go smoothly as often as they are needed.</li>
        </ul>
      </BlankSlateCard>
    </Box>
  );
};
