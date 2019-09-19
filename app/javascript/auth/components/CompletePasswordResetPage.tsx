import * as React from "react";
import { authClient } from "../../superlib/axios";
import { Alert } from "../../superlib/Alert";
import { Heading, Button, Box, Anchor } from "grommet";
import { PageBox } from "./PageBox";
import { SuperForm, Input, FieldBox } from "superlib/superform";
import queryString from "query-string";
import { RouteComponentProps } from "react-router";

interface CompletePasswordResetFormValues {
  password: string;
}

interface ForgotPasswordPageState {
  message?: string;
  success: boolean;
}

export default class CompletePasswordResetPage extends React.Component<RouteComponentProps, ForgotPasswordPageState> {
  state: ForgotPasswordPageState = { success: false };

  handleSubmit = async (doc: CompletePasswordResetFormValues) => {
    const params = queryString.parse(this.props.location.search);

    try {
      await authClient.put("password.json", { user: { ...doc, reset_password_token: params.reset_password_token } });
      this.setState({ message: "", success: true });
    } catch (error) {
      let message = "There was an error trying to reset your password. Please try again.";
      this.setState({ message });
    }
  };

  render() {
    return (
      <PageBox documentTitle="Reset Password">
        <Box pad="small">
          <Heading>Reset Superpro Password</Heading>
        </Box>
        {this.state.message && <Alert type="error" message={this.state.message} />}
        {this.state.success && (
          <Box pad="small">
            <Alert
              type="success"
              message={
                <>
                  Your password has been successfully reset.
                  <br />
                  <Anchor href="/">Click here to enter Superpro.</Anchor>
                </>
              }
            />
          </Box>
        )}
        {this.state.success || (
          <SuperForm<CompletePasswordResetFormValues> onSubmit={this.handleSubmit} initialValues={{ password: "" }}>
            {() => (
              <>
                <FieldBox label="New Password" path="password">
                  <Input path="password" type="password" />
                </FieldBox>
                <Button type="submit" primary label="Reset Password" margin={{ top: "medium" }} data-test-id="reset-password-submit" />
              </>
            )}
          </SuperForm>
        )}
      </PageBox>
    );
  }
}
