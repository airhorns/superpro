import * as React from "react";
import { client } from "../../flurishlib/axios";
import { Alert } from "../../flurishlib/Alert";
import { Heading, Button, Box } from "grommet";
import { PageBox } from "./PageBox";
import { SuperForm, Input, FieldBox } from "flurishlib/superform";

interface LoginFormValues {
  email: string;
  password: string;
}

interface LoginPageState {
  message?: string;
}
export class LoginPage extends React.Component<{}, LoginPageState> {
  state: LoginPageState = {};

  handleSubmit = async (doc: LoginFormValues) => {
    try {
      const response = await client.post("/auth/api/sign_in.json", { user: doc });
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

  render() {
    return (
      <PageBox documentTitle="Login">
        <Box pad="small">
          <Heading>Login to Flurish</Heading>
        </Box>
        {this.state.message && <Alert type="error" message={this.state.message} />}
        <SuperForm<LoginFormValues>
          onSubmit={this.handleSubmit}
          initialValues={{ email: "", password: "" }}
          // validationSchema={Yup.object().shape({
          //   email: Yup.string().required(),
          //   password: Yup.string().required()
          // })}
        >
          <FieldBox label="Email" path="email">
            <Input path="email" />
          </FieldBox>
          <FieldBox label="Password" path="password">
            <Input path="password" type="password" />
          </FieldBox>
          <Button type="submit" primary label="Login" margin={{ top: "medium" }} data-test-id="login-submit" />
        </SuperForm>
      </PageBox>
    );
  }
}
