declare module "lru-memoize" {
  function Memoizer(
    limit?: number,
    equals?: (...args: any[]) => boolean,
    deepObjects?: boolean
  ): <T extends (...args: any[]) => any>(func: T) => (...funcArgs: Parameters<T>) => ReturnType<T>;
  export default Memoizer;
}
