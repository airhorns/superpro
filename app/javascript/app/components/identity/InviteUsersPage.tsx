import React from "react";
import { Page } from "../common";
import { Box, Text, Button } from "grommet";
import { Row, mutationSuccess, toast } from "superlib";
import { Invite } from "../common/SuperproIcons";
import gql from "graphql-tag";
import { SuperForm, Input, SuperFormController } from "superlib/superform";
import { InviteNewUserComponent, InviteNewUserMutationFn } from "app/app-graph";

gql`
  mutation InviteNewUser($user: UserInviteAttributes!) {
    inviteUser(user: $user) {
      success
      errors {
        fullMessage
      }
    }
  }
`;

interface InviteFormValues {
  user: {
    email?: string;
  };
}

export default class InviteUsersPage extends Page {
  handleSubmit = async (form: SuperFormController<InviteFormValues>, mutate: InviteNewUserMutationFn) => {
    const result = await mutate({
      variables: {
        user: form.getValue("user")
      }
    });

    if (mutationSuccess(result, "inviteUser")) {
      toast.success("User invited!");
      form.setValue("user", { email: "" });
    } else {
      toast.error("There was an error inviting this user. Please try again.");
    }
  };

  render() {
    return (
      <Page.Layout title="Invite Users">
        <Box align="center" gap="small">
          <Text>
            Invite your team to Superpro! Enter an email below and we&apos;ll send them an email asking them to join your Superpro account.
          </Text>
          <InviteNewUserComponent>
            {mutate => (
              <SuperForm<InviteFormValues> initialValues={{ user: {} }} onSubmit={(doc, form) => this.handleSubmit(form, mutate)}>
                {() => (
                  <>
                    <Row gap="small">
                      <Invite />
                      <Input path="user.email" />
                    </Row>
                    <Button type="submit" primary label="Invite" margin={{ top: "medium" }} data-testid="invite-submit" />
                  </>
                )}
              </SuperForm>
            )}
          </InviteNewUserComponent>
        </Box>
      </Page.Layout>
    );
  }
}
