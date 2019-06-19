import * as React from "react";
import { RouteComponentProps } from "react-router";
import { Heading, Box, Button } from "grommet";
import { PageBox } from "./PageBox";
import { SuperForm, FieldBox, Input } from "flurishlib/superform";
import { authClient } from "flurishlib/axios";

interface SignUpFormValues {
  user: {
    mutation_client_id: string;
    email?: string;
    full_name?: string;
    password?: string;
    password_confirmation?: string;
  };
  account: {
    mutation_client_id: string;
    name?: string;
  };
}

export default class SignUpPage extends React.Component<RouteComponentProps> {
  handleSubmit = async (doc: SignUpFormValues) => {
    try {
      const response = await authClient.post("sign_up.json", doc);
      if (response.data.success) {
        window.location = response.data.redirect_url;
      } else {
        this.setState({ message: response.data.message });
      }
    } catch (error) {
      let message = "There was an error trying to log in. Please try again.";
      if (error.response && error.response.data && error.response.data.message) {
        message = error.response.data.message;
      }
      this.setState({ message });
    }
  };

  public render() {
    return (
      <PageBox documentTitle="Sign Up">
        <Heading level="1">Sign Up for Flurish</Heading>
        <SuperForm<SignUpFormValues>
          initialValues={{ user: { mutation_client_id: "user" }, account: { mutation_client_id: "account" } }} // eslint-disable-line
          onSubmit={this.handleSubmit}
        >
          {() => (
            <Box>
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
              <FieldBox label="Business Name" path="account.name">
                <Input path="account.name" />
              </FieldBox>
              <Button type="submit" primary label="Sign Up" margin={{ top: "medium" }} data-test-id="sign-up-submit" />
            </Box>
          )}
        </SuperForm>
      </PageBox>
    );
  }
}
