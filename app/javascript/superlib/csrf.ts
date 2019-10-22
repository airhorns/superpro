export const csrfToken = () => {
  const csrfMeta = document.querySelector("meta[name=csrf-token]");
  if (csrfMeta) {
    return csrfMeta.getAttribute("content");
  } else {
    if (typeof process != "undefined" && process.env.NODE_ENV == "test") {
      return "test-token";
    } else {
      throw new Error("CSRF token meta tag not found, can't make verified requests to the backend");
    }
  }
};
