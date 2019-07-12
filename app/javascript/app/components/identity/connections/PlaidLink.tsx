import React from "react";
import Script from "react-load-script";
import { Button } from "grommet";

export interface PlaidLinkProps {
  // ApiVersion flag to use new version of Plaid API
  apiVersion?: string;

  // Displayed once a user has successfully linked their account
  clientName: string;

  // The Plaid API environment on which to create user accounts.
  // For development and testing, use tartan. For production, use production
  env: "tartan" | "sandbox" | "development" | "production";

  // Open link to a specific institution, for a more custom solution
  institution?: string;

  // The public_key associated with your account; available from
  // the Plaid dashboard (https://dashboard.plaid.com)
  publicKey: string;

  // The Plaid products you wish to use, an array containing some of connect,
  // auth, identity, income, transactions, assets
  product: ("connect" | "info" | "auth" | "identity" | "income" | "transactions" | "assets" | "holdings")[];

  // Specify an existing user's public token to launch Link in update mode.
  // This will cause Link to open directly to the authentication step for
  // that user's institution.
  token: string;

  // Specify a user object to enable all Auth features. Reach out to your
  // account manager or integrations@plaid.com to get enabled. See the Auth
  // [https://plaid.com/docs#auth] docs for integration details.
  user?: {
    // Your user's legal first and last name
    legalName: string;
    // Your user's associated email address
    emailAddress: string;
  };

  // Set to true to launch Link with the 'Select Account' pane enabled.
  // Allows users to select an individual account once they've authenticated
  selectAccount?: boolean;

  // Specify a webhook to associate with a user.
  webhook?: string;

  // A function that is called when a user has successfully onboarded their
  // account. The function should expect two arguments, the public_key and a
  // metadata object
  onSuccess: (token: any, metadata: any) => void;

  // A function that is called when a user has specifically exited Link flow
  onExit?: (error?: any) => void;

  // A function that is called when the Link module has finished loading.
  // Calls to plaidLinkHandler.open() prior to the onLoad callback will be
  // delayed until the module is fully loaded.
  onLoad?: () => void;

  // A function that is called during a user's flow in Link.
  // See
  onEvent?: (event: any) => void;

  // Button Styles as an Object
  style?: any;

  // Button Class names as a String
  className?: string;

  label?: string;
  plain?: boolean;
}

interface PlaidLinkState {
  disabledButton: boolean;
  linkLoaded: boolean;
  initializeURL: string;
}

export class PlaidLink extends React.Component<PlaidLinkProps, PlaidLinkState> {
  constructor(props: PlaidLinkProps) {
    super(props);
    this.state = {
      disabledButton: true,
      linkLoaded: false,
      initializeURL: "https://cdn.plaid.com/link/v2/stable/link-initialize.js"
    };
  }

  static defaultProps = {
    apiVersion: "v2",
    env: "sandbox",
    institution: null,
    selectAccount: false,
    token: null,
    style: {
      padding: "6px 4px",
      outline: "none",
      background: "#FFFFFF",
      border: "2px solid #F1F1F1",
      borderRadius: "4px"
    }
  };

  linkHandler: any;

  onScriptError = () => {
    console.error("There was an issue loading the link-initialize.js script");
  };

  onScriptLoaded = () => {
    this.linkHandler = (window as any).Plaid.create({
      apiVersion: this.props.apiVersion,
      clientName: this.props.clientName,
      env: this.props.env,
      key: this.props.publicKey,
      user: this.props.user,
      onExit: this.props.onExit,
      onLoad: this.handleLinkOnLoad,
      onEvent: this.props.onEvent,
      onSuccess: this.props.onSuccess,
      product: this.props.product,
      selectAccount: this.props.selectAccount,
      token: this.props.token,
      webhook: this.props.webhook
    });

    this.setState({ disabledButton: false });
  };

  handleLinkOnLoad = () => {
    if (this.props.onLoad != null) {
      this.props.onLoad();
    }
    this.setState({ linkLoaded: true });
  };

  handleOnClick = (event: any) => {
    const institution = this.props.institution || null;
    if (this.linkHandler) {
      this.linkHandler.open(institution);
    }
  };

  exit(configurationObject: any) {
    if (this.linkHandler) {
      this.linkHandler.exit(configurationObject);
    }
  }

  render() {
    return (
      <>
        <Button
          onClick={this.handleOnClick}
          disabled={this.state.disabledButton}
          style={this.props.style}
          className={this.props.className}
          label={this.props.label}
          plain={this.props.plain}
        >
          {this.props.children}
        </Button>
        <Script url={this.state.initializeURL} onError={this.onScriptError} onLoad={this.onScriptLoaded} />
      </>
    );
  }
}
