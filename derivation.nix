{ rustPlatform
, nix-gitignore
, buildType ? "release"
, hostPlatform
, lib
, libiconv
, _arg'src ? nix-gitignore.gitignoreSourcePure [ ./.gitignore ''
  /.github
  /.git
  *.nix
'' ] ./.
}: with lib; let
  cargoToml = importTOML ./Cargo.toml;
in rustPlatform.buildRustPackage {
  pname = cargoToml.package.name;
  version = cargoToml.package.version;

  buildInputs = optionals hostPlatform.isDarwin [ libiconv ];

  src = _arg'src;
  cargoSha256 = "sha256-goUsJnjutah8k3d+DrtaFAndX17ZIuq/Kr3hWt2+yEA=";
  inherit buildType;

  doCheck = false;

  meta = {
    platforms = platforms.unix;
  };
}
