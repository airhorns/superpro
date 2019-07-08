import axios from "axios";

const csrfMeta = document.querySelector("meta[name=csrf-token]");
if (!csrfMeta) {
  throw new Error("CSRF token meta tag not found, can't make verified requests to the backend");
}

export const authClient = axios.create({
  baseURL: (window as any).INJECTED_SETTINGS.authDomain + "/auth/api/",
  maxRedirects: 0,
  headers: {
    "X-CSRF-Token": csrfMeta.getAttribute("content")
  }
});
