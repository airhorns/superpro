import * as React from "react";
import queryString from "query-string";
import { RouteComponentProps } from "react-router";
import { Heading, Box, Button, Text } from "grommet";
import { PageBox } from "./PageBox";
import { SuperForm, SuperFormController, FieldBox, Input } from "superlib/superform";
import { authClient } from "superlib/axios";
import { Alert, applyResponseErrors, SimplePromise } from "superlib";

interface AcceptInviteFormValues {
  user: {
    mutation_client_id: string;
    email: string;
    full_name?: string;
    password?: string;
    password_confirmation?: string;
  };
}

interface AcceptInvitePageState {
  message?: string;
}
export default class AcceptInvitePage extends React.Component<RouteComponentProps, AcceptInvitePageState> {
  state: AcceptInvitePageState = {};

  handleSubmit = async (doc: AcceptInviteFormValues, form: SuperFormController<AcceptInviteFormValues>) => {
    const params = queryString.parse(this.props.location.search);

    try {
      const response = await authClient.put("invitation.json", {
        user: {
          invitation_token: params.invitation_token,
          ...doc.user
        }
      });

      if (response.data.success) {
        window.location = response.data.redirect_url;
      } else {
        this.setState({ message: response.data.message });
      }
    } catch (error) {
      let message = "There was an error signing up. Please try again.";
      if (error.response && error.response.data && error.response.data.message) {
        message = error.response.data.message;
      }
      if (error.response && error.response.data && error.response.data.errors) {
        applyResponseErrors(error.response.data.errors, form);
      }
      this.setState({ message });
    }
  };

  loadInviteData = () => {
    const params = queryString.parse(this.props.location.search);
    return authClient.get<{ success: boolean; user: { email: string } }>("invitation/accept.json", {
      params: { invitation_token: params.invitation_token }
    });
  };

  public render() {
    return (
      <PageBox documentTitle="Welcome to Superpro">
        <Box gap="medium">
          <Heading level="1">Welcome to Superpro</Heading>
          <Text>You&apos;ve been invited to join. Please fill out your details to create your account below.</Text>
          <SimplePromise callback={this.loadInviteData}>
            {response => {
              if (!response.data.success) {
                return (
                  <Alert
                    type="error"
                    message="This invite code was not found. It may have expired. If you believe this is an error, please contact the account owner, or message us at support@superpro.io."
                  />
                );
              } else {
                return (
                  <SuperForm<AcceptInviteFormValues>
                    initialValues={{
                      user: { mutation_client_id: "user", ...response.data.user }
                    }}
                    onSubmit={this.handleSubmit}
                  >
                    {() => (
                      <Box>
                        {this.state.message && <Alert type="error" message={this.state.message} />}
                        <FieldBox label="Email" path="user.email">
                          <Input path="user.email" />
                        </FieldBox>
                        <FieldBox label="Your Name" path="user.full_name">
                          <Input path="user.full_name" />
                        </FieldBox>
                        <FieldBox label="Password" path="user.password">
                          <Input path="user.password" type="password" />
                        </FieldBox>
                        <FieldBox label="Password Confirmation" path="user.password_confirmation">
                          <Input path="user.password_confirmation" type="password" />
                        </FieldBox>
                        <Button type="submit" primary label="Complete Sign Up" margin={{ top: "medium" }} data-testid="sign-up-submit" />
                      </Box>
                    )}
                  </SuperForm>
                );
              }
            }}
          </SimplePromise>
        </Box>
      </PageBox>
    );
  }
}
