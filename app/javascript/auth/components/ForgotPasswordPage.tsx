import * as React from "react";
import { authClient } from "../../superlib/axios";
import { Alert } from "../../superlib/Alert";
import { Heading, Button, Box } from "grommet";
import { PageBox } from "./PageBox";
import { SuperForm, Input, FieldBox } from "superlib/superform";
import { toast } from "superlib";

interface ForgotPasswordFormValues {
  email: string;
}

interface ForgotPasswordPageState {
  message?: string;
}

export default class ForgotPasswordPage extends React.Component<{}, ForgotPasswordPageState> {
  state: ForgotPasswordPageState = {};

  handleSubmit = async (doc: ForgotPasswordFormValues) => {
    try {
      await authClient.post("password.json", { user: doc });
      this.setState({ message: "" });
      toast.success("An email has been sent with instructions to reset your password.");
    } catch (error) {
      let message = "There was an error trying to reset your password. Please try again.";
      if (error.response && error.response.data && error.response.data.errors && error.response.data.errors["email"]) {
        message = "Your email couldn't be found. Please try again.";
      }
      this.setState({ message });
    }
  };

  render() {
    return (
      <PageBox documentTitle="Reset Password">
        <Box pad="small">
          <Heading>Reset Superpro Password</Heading>
        </Box>
        <p>
          If you&apos;ve forgotten your password, enter your email below. We&apos;ll send you an email with instructions to reset your
          password.
        </p>
        {this.state.message && <Alert type="error" message={this.state.message} />}
        <SuperForm<ForgotPasswordFormValues> onSubmit={this.handleSubmit} initialValues={{ email: "" }}>
          {() => (
            <>
              <FieldBox label="Email" path="email">
                <Input path="email" />
              </FieldBox>
              <Button type="submit" primary label="Send Email" margin={{ top: "medium" }} data-test-id="forgot-password-submit" />
            </>
          )}
        </SuperForm>
      </PageBox>
    );
  }
}
