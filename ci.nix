{ config, pkgs, lib, ... }: with pkgs; with lib; let
  mosh-server-upnp = import ./. { inherit pkgs; };
  artifactRoot = ".ci/artifacts";
  artifacts = "${artifactRoot}/bin/mosh-server-upnp*";
  musl64 = pkgsCross.musl64.pkgsStatic;
  mosh-server-upnp-static = (musl64.callPackage ./derivation.nix {
    inherit ((import config.channels.rust.path { pkgs = musl64; }).stable) rustPlatform;
  }).overrideAttrs (old: {
    # XXX: why is this needed?
    NIX_LDFLAGS = old.NIX_LDFLAGS or "" + " -static";
    RUSTFLAGS = old.RUSTFLAGS or "" + " -C default-linker-libraries=yes";
  });
  mosh-server-upnp-stable = (mosh-server-upnp.override {
    inherit ((import config.channels.rust.path { inherit pkgs; }).stable) rustPlatform;
  }).overrideAttrs (_: {
    doCheck = true;
  });
in {
  config = {
    name = "mosh-server-upnp";
    ci.gh-actions.enable = true;
    cache.cachix.arc.enable = true;
    channels = {
      nixpkgs = {
        # see https://github.com/arcnmx/nixexprs-rust/issues/10
        args.config.checkMetaRecursively = false;
      };
      rust = "master";
    };
    tasks = {
      build.inputs = singleton mosh-server-upnp-stable;
    };
    jobs = {
      nixos = {
        tasks = {
          build-static.inputs = singleton mosh-server-upnp-static;
        };
        artifactPackages.musl64 = mosh-server-upnp-static;
      };
      macos = {
        system = "x86_64-darwin";
        artifactPackages.macos = mosh-server-upnp-stable;
      };
    };

    # XXX: symlinks are not followed, see https://github.com/softprops/action-gh-release/issues/182
    artifactPackage = runCommand "mosh-server-upnp-artifacts" { } (''
      mkdir -p $out/bin
    '' + concatStringsSep "\n" (mapAttrsToList (key: mosh-server-upnp: ''
        cp ${mosh-server-upnp}/bin/mosh-server-upnp${mosh-server-upnp.stdenv.hostPlatform.extensions.executable} $out/bin/mosh-server-upnp-${key}${mosh-server-upnp.stdenv.hostPlatform.extensions.executable}
    '') config.artifactPackages));

    gh-actions = {
      jobs = mkIf (config.id != "ci") {
        ${config.id} = {
          permissions = {
            contents = "write";
          };
          step = {
            artifact-build = {
              order = 1100;
              name = "artifact build";
              uses = {
                # XXX: a very hacky way of getting the runner
                inherit (config.gh-actions.jobs.${config.id}.step.ci-setup.uses) owner repo version;
                path = "actions/nix/build";
              };
              "with" = {
                file = "<ci>";
                attrs = "config.jobs.${config.jobId}.artifactPackage";
                out-link = artifactRoot;
              };
            };
            artifact-upload = {
              order = 1110;
              name = "artifact upload";
              uses.path = "actions/upload-artifact@v2";
              "with" = {
                name = "mosh-server-upnp";
                path = artifacts;
              };
            };
            release-upload = {
              order = 1111;
              name = "release";
              "if" = "startsWith(github.ref, 'refs/tags/')";
              uses.path = "softprops/action-gh-release@v1";
              "with".files = artifacts;
            };
          };
        };
      };
    };
  };
  options = {
    artifactPackage = mkOption {
      type = types.package;
    };
    artifactPackages = mkOption {
      type = with types; attrsOf package;
    };
  };
}
