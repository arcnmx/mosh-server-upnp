{
  description = "use mosh across a NAT";
  inputs = {
    flakelib.url = "github:flakelib/fl";
    nixpkgs = { };
  };
  outputs = { flakelib, ... }@inputs: flakelib {
    inherit inputs;
    config = {
      name = "mosh-server-upnp";
    };
    packages.mosh-server-upnp = {
      __functor = _: import ./derivation.nix;
      fl'config.args = {
        _arg'src.fallback = inputs.self.outPath;
      };
    };
    defaultPackage = "mosh-server-upnp";
  };
}
