import React from "react";
import { uniq, filter } from "lodash";
import shortid from "shortid";
import { Heading, Box, Button, Text } from "grommet";
import { HelpTip, Row } from "flurishlib";
import { Add } from "../common/FlurishIcons";
import { useSuperForm } from "flurishlib/superform";
import { BudgetFormValues, EmptyLine } from "./BudgetForm";

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

export const BudgetFormNewSectionlist = () => {
  const form = useSuperForm<BudgetFormValues>();
  const existingSections = new Set(uniq(form.doc.budget.sections.map(section => section.name)));
  const suggestedSections = filter(BudgetSectionSuggestions, suggestion => !existingSections.has(suggestion.name));
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
      <Heading level="3">Add sections</Heading>
      {suggestedSections.map(suggestion => {
        const onClick = (_e: React.SyntheticEvent) => createNewSection(suggestion.name);

        if (form.doc.budget.sections.length > 2) {
          return (
            <Box width="medium" key={suggestion.name}>
              <Button
                as="div"
                onClick={onClick}
                margin="small"
                data-test-id={`add-section-${suggestion.name}`}
                label={
                  <Row justify="between" gap="small">
                    {suggestion.name}
                    <HelpTip text={suggestion.description} />
                  </Row>
                }
              />
            </Box>
          );
        } else {
          return (
            <Box pad="small" key={suggestion.name}>
              <Heading level="4">{suggestion.name}</Heading>
              <Text>{suggestion.description}</Text>
              <Box align="start">
                <Button
                  key={suggestion.name}
                  data-test-id={`add-section-${suggestion.name}`}
                  as="div"
                  onClick={onClick}
                  margin="small"
                  icon={<Add />}
                  label={`Add ${suggestion.name}`}
                />
              </Box>
            </Box>
          );
        }
      })}
      {(() => {
        const onClick = (_e: React.SyntheticEvent) => createNewSection("New Section");

        return (
          <Box width="medium">
            <Button
              as="div"
              onClick={onClick}
              margin="small"
              label={
                <Row justify="between" gap="small">
                  Add Custom
                  <HelpTip text="A custom section that can represent any other kind of expense or revenue in your budget." />
                </Row>
              }
            />
          </Box>
        );
      })()}
    </Box>
  );
};
