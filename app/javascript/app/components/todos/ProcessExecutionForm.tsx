import React from "react";
import { Box } from "grommet";
import { FieldBox, Select } from "flurishlib/superform";
import { UserCard, UserCardProps } from "../common";

export const ProcessExecutionForm = (props: { users: UserCardProps["user"][] }) => (
  <Box pad="small">
    <FieldBox label="Owner" path="processExecution.ownerId">
      <Select
        path="processExecution.ownerId"
        options={props.users.map(user => ({
          value: user.id,
          label: <UserCard user={user} />
        }))}
      ></Select>
    </FieldBox>
  </Box>
);
