declare module "grommet/utils/styles";
declare module "grommet-icons/metadata" {
  let Metadata: Metadata;
  interface Metadata {
    [key: string]: string[];
  }
  export default Metadata;
}
