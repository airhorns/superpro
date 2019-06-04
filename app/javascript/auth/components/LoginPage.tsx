import * as React from "react";
import { client } from "../../flurishlib/axios";
import { Formant } from "../../flurishlib/formant";
import { Alert } from "../../flurishlib/Alert";
import { Heading, Button, Box } from "grommet";
import { PageBox } from "./PageBox";
import { FormikActions } from "formik";
import * as Yup from "yup";

interface LoginFormValues {
  email: string;
  password: string;
}

interface LoginPageState {
  message?: string;
}
export class LoginPage extends React.Component<{}, LoginPageState> {
  state: LoginPageState = {};

  handleSubmit = async (details: LoginFormValues, actions: FormikActions<LoginFormValues>) => {
    try {
      const response = await client.post("/auth/api/sign_in.json", { user: details });
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
    actions.setSubmitting(false);
  };

  render() {
    return (
      <PageBox documentTitle="Login">
        <Box pad="small">
          <Heading>Login to Flurish</Heading>
        </Box>
        {this.state.message && <Alert type="error" message={this.state.message} />}
        <Formant<LoginFormValues>
          onSubmit={this.handleSubmit}
          initialValues={{ email: "", password: "" }}
          validationSchema={Yup.object().shape({
            email: Yup.string().required(),
            password: Yup.string().required()
          })}
        >
          <Formant.Input name="email" label="Email" />
          <Formant.Input name="password" type="password" label="Password" />
          <Button type="submit" primary label="Login" margin={{ top: "medium" }} data-test-id="login-submit" />
        </Formant>
      </PageBox>
    );
  }
}
