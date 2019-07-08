import React from "react";
import { uniq, filter } from "lodash";
import shortid from "shortid";
import { Heading, Box, Button, Text } from "grommet";
import { Add } from "../common/SuperproIcons";
import { useSuperForm } from "superlib/superform";
import { BudgetFormValues, EmptyLine } from "./BudgetForm";
import { Row, SimpleModal } from "superlib";

const Lorem =
  "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum";

const BudgetSectionSuggestions: { name: string; description: string; suggestedItems: { name: string }[] }[] = [
  {
    name: "Services",
    description: Lorem,
    suggestedItems: []
  },
  {
    name: "Facilities",
    description: "This other thing",
    suggestedItems: []
  },
  {
    name: "Legal",
    description: Lorem,
    suggestedItems: []
  },
  {
    name: "Fixed Assets",
    description: "Another description",
    suggestedItems: []
  },
  {
    name: "Materials",
    description: "Whatever",
    suggestedItems: []
  }
];

const BudgetFormNewSectionButton = (props: { name: string; description: string; disabled?: boolean; onClick: () => void }) => {
  return (
    <Button
      data-test-id={`add-section-${props.name}`}
      as="div"
      onClick={props.onClick}
      margin="small"
      hoverIndicator
      disabled={props.disabled}
    >
      <Row gap="small" pad="small">
        <Add size="large" />
        <Box pad="small">
          <Heading level="4">{props.name}</Heading>
          <Text>{props.description}</Text>
          <Box align="start"></Box>
        </Box>
      </Row>
    </Button>
  );
};

export const BudgetFormNewSectionList = (props: { onAdd?: () => void }) => {
  const form = useSuperForm<BudgetFormValues>();
  const existingSections = new Set(uniq(form.doc.budget.sections.map(section => section.name)));
  const newSectionSuggestions = filter(BudgetSectionSuggestions, suggestion => !existingSections.has(suggestion.name));
  const existingSectionSuggestions = filter(BudgetSectionSuggestions, suggestion => existingSections.has(suggestion.name));
  const sectionHelpers = form.arrayHelpers("budget.sections");
  const lineHelpers = form.arrayHelpers("budget.lines");

  const createNewSection = (name: string) => {
    const newSectionId = shortid.generate();
    form.batch(() => {
      sectionHelpers.push({
        name: name,
        id: newSectionId
      });

      lineHelpers.push({ ...EmptyLine, id: shortid.generate(), sectionId: newSectionId, sortOrder: 0 });
    });
  };

  return (
    <Box>
      <Heading level="3">Add a new section</Heading>
      <Text>
        Sections represent categories of expected revenue or expenses that make it easier to group the different things happening to your
        business. Pick from the section templates below or create your own using the Custom Section button.
      </Text>
      <BudgetFormNewSectionButton
        name="Custom"
        description="A custom section for whatever you want"
        onClick={() => {
          props.onAdd && props.onAdd();
          createNewSection("New Section");
        }}
      />
      {newSectionSuggestions.map(suggestion => (
        <BudgetFormNewSectionButton
          key={suggestion.name}
          {...suggestion}
          onClick={() => {
            props.onAdd && props.onAdd();
            createNewSection(suggestion.name);
          }}
        />
      ))}
      {existingSectionSuggestions.map(suggestion => (
        <BudgetFormNewSectionButton key={name} description {...suggestion} disabled onClick={() => {}} />
      ))}
    </Box>
  );
};

export const BudgetFormNewSectionModal = () => {
  return (
    <Box pad="small">
      <SimpleModal triggerIcon={<Add />} triggerLabel="Add Section">
        {setShow => <BudgetFormNewSectionList onAdd={() => setShow(false)} />}
      </SimpleModal>
    </Box>
  );
};
