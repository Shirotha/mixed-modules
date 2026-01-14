{ lib, ... }:
with lib; rec {
  /*
    transposeAttrs :: attr -> attr

    transposes an attribute set of the form `<a>.<b>.<x>` to `<b>.<a>.<x>`.
  */
  transposeAttrs = concatMapAttrs (a: mapAttrs (b: x: { a = x; }));

  nestedMapAttrsWith =
    iter:
    n: f: attr:
      if n <= 0
      then f attr
      else attr|>iter
        (name: inner:
          nestedMapAttrsWith iter (n - 1) (f name) inner
        );
  /*
    nestedMapAttrs :: n:int -> ((str ->)...n a -> b) -> attr -> attr

    maps values of a nested attribute set multiple levels deep.
  */
  nestedMapAttrs = nestedMapAttrsWith mapAttrs;
  /*
    nestedMapAttrsToList :: n:int -> ((str ->)...n a -> b) -> attr -> [b]

    maps values of a nested attribute set multiple levels deep
    and returns the values as a nested list.
  */
  nestedMapAttrsToList = nestedMapAttrsWith mapAttrsToList;

  unwrapModule =
    module:
      if module?imports && (length module.imports) == 1
      then unwrapModule<|head module.imports
      else module;

  types'.scopedModule =
    {
      host ? [],
      user ? [],
    }:
    let
      untilOption =
        path: l: r:
          (l?_type && l._type == "option")
            || (r?_type && r._type == "option");
      merge = x: y: recursiveUpdateUntil untilOption x (unwrapModule y);
      hostModuleType = types.submodule {
        options = foldl' merge {
          system = mkOption {
            type = types.str;
          };
        } host;
      };
      userModuleType = types.submodule {
        options = foldl' merge {} user;
      };
    in
      types.submodule { options = {
        host = mkOption {
          type = types.lazyAttrsOf hostModuleType;
          default = {};
        };
        user = mkOption {
          type = types.lazyAttrsOf<|types.lazyAttrsOf userModuleType;
          default = {};
        };
      };};

  applyScopedModule =
    {
      default ? null,
    }:
    module:
    let
      module' = unwrapModule module;
    in if default == null || module'?host || module'?user
      then module'
      else assert elem default ["host" "user"]; { "${default}" = module'; };

  applyScopedModules =
    args: modules:
      modules
        # deferredModule.merge does not run for a single definition and in that case it returns an attribute set
        |> flatten
        |> map (applyScopedModule args)
        |> foldl' mergeAttrsConcatenateValues {};

  # TODO: change default priority
  # - host: special(100) < host(200) < user(300) < shared(400)
  # - user: special(100) < user(200) < host(300) < shared(400)
  mergeScopedModules =
    {
      shared, # `listOf scopedModule`
      host, # `attrsOf listOf scopedModule`
      user, # `attrsOf listOf scopedModule`
      special, # `attrsOf attrsOf listOf scopedModule`
    }: {
      host = special|>mapAttrs (host': users':
        mkMerge (
            # mkMerge does not work properly with empty lists
            shared.host or [{}]
              ++ host.${host'}.host or []
              ++ (users'
                |> mapAttrsToList (user': _: user.${user'}.host or [])
                |> flatten)
              ++ (users'|>attrValues|>concatMap (special': special'.host or []))
          )
      );
      user = special|>nestedMapAttrs 2 (host': user': special':
        mkMerge (
          shared.user or []
            ++ host.${host'}.user or []
            ++ user.${user'}.user or []
            ++ special'.user or []
          )
      );
    };
}
