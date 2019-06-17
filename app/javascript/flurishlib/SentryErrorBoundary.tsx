import React from "react";
import * as Sentry from "@sentry/browser";

const globalVar = typeof window === "undefined" ? { environment: "unknown", entrypoint: "unknown" } : (window as any);
// Only send sentry errors in prod, modify but don't commit this code if you want to test sentry things
if (globalVar.FLURISH_ENVIRONMENT === "production") {
  Sentry.init({
    dsn: "https://c494714d521243ebab42377f494ff159@sentry.io/1484795",
    environment: globalVar.FLURISH_ENVIRONMENT
  });
}

Sentry.configureScope(scope => {
  scope.setTag("entrypoint", globalVar.FLURISH_ENTRYPOINT);
});

export class SentryErrorBoundary extends React.Component<{}, { error?: Error; eventId?: string }> {
  constructor(props: {}) {
    super(props);
    this.state = { error: undefined, eventId: undefined };
  }

  componentDidCatch(error: Error, errorInfo: any) {
    this.setState({ error });
    console.error(error, errorInfo);
    Sentry.withScope(scope => {
      scope.setExtras(errorInfo);
      const eventId = Sentry.captureException(error);
      this.setState({ eventId });
    });
  }

  render() {
    if (this.state.error) {
      return <a onClick={() => Sentry.showReportDialog({ eventId: this.state.eventId })}>Report feedback</a>;
    } else {
      return this.props.children;
    }
  }
}
