import axios from "axios";

const csrfMeta = document.querySelector("meta[name=csrf-token]");
if (!csrfMeta) {
  throw new Error("CSRF token meta tag not found, can't make verified requests to the backend");
}

export const client = axios.create();
axios.defaults.headers["X-CSRF-Token"] = csrfMeta.getAttribute("content");
axios.defaults.maxRedirects = 0;
