{ pkgs ? import <nixpkgs> { } }: let
  mosh-server-upnp = pkgs.callPackage ./derivation.nix { };
  static = pkgs.pkgsCross.musl64.pkgsStatic.callPackage ./derivation.nix { };
in mosh-server-upnp // {
  inherit mosh-server-upnp static;
}
