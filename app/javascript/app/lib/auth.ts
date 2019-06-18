import { authClient } from "../../flurishlib/axios";
import { toast } from "../../flurishlib";

export const signOut = async () => {
  try {
    const response = await authClient.delete("sign_out.json");
    (window as any).location = response.headers["Location"] || "/";
  } catch (error) {
    console.error(error);
    toast.error("There was an error logging you out");
  }
};
