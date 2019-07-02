import { KeyUtils } from "slate";
import shortid from "shortid";

KeyUtils.setGenerator(shortid.generate);
