import { authClient } from "../../superlib/axios";
import { toast } from "../../superlib";

export const signOut = async () => {
  try {
    const response = await authClient.delete("sign_out.json");
    (window as any).location = response.headers["Location"] || "/";
  } catch (error) {
    console.error(error);
    toast.error("There was an error logging you out");
  }
};
