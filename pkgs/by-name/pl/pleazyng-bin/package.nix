{
  lib,
  stdenvNoCC,
  fetchurl,
  buildFHSEnv,
  python3,
}:
let
  version = "3.0.7";
  sources = {
    x86_64-linux = {
      arch = "x64";
      sha256 = "fbe98082916f0131981d71e4fee4dba900a2da1b62d9f82b9a3555e1da09fde9";
    };
    aarch64-linux = {
      arch = "arm64";
      sha256 = "6d02b9fc2d7fb142093e9b5b34846674339ae068c722e51db80f65413a31643d";
    };
  };
  source =
    sources.${stdenvNoCC.hostPlatform.system}
      or (throw "Pleazyng release bundles support x86_64-linux and aarch64-linux");
  bundle = stdenvNoCC.mkDerivation {
    pname = "pleazyng-bundle";
    inherit version;
    src = fetchurl {
      url = "https://github.com/snapetech-org/pleazyng/releases/download/v3.0.7/pleazyng-linux-${source.arch}.tar.gz";
      inherit (source) sha256;
    };
    # Preserve native engines, models and providers exactly as released.
    dontUnpack = true;
    dontFixup = true;
    nativeBuildInputs = [ python3 ];
    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib/pleazyng
      tar -xzf $src -C $out/lib/pleazyng
      test -x $out/lib/pleazyng/pleazyng
      test -f $out/lib/pleazyng/pleazyng.sh
      chmod +x $out/lib/pleazyng/pleazyng.sh
      python3 ${./relocate-caches.py} $out/lib/pleazyng
      runHook postInstall
    '';
  };
in
buildFHSEnv {
  name = "pleazyng";
  # The FHS environment keeps the published bundle and launcher together.
  # It is a compatibility environment, not a security sandbox.
  targetPkgs =
    p: with p; [
      bash
      coreutils
      gtk3
      webkitgtk_4_1
      libsecret
      libepoxy
      alsa-lib
      libevdev
      glib
      wayland
      libglvnd
      libva
      libvdpau
      vulkan-loader
      libdrm
      mesa
      libx11
      libxcb
      libxext
      libgbm
      fontconfig
      xdg-utils
      cacert
    ];
  runScript = "${bundle}/lib/pleazyng/pleazyng.sh";
  extraInstallCommands = ''
    install -Dm644 ${./org.snapetech.pleazyng.desktop} \
      $out/share/applications/org.snapetech.pleazyng.desktop
    install -Dm644 ${bundle}/lib/pleazyng/pleazyng.png \
      $out/share/icons/hicolor/512x512/apps/pleazyng.png
  '';
  meta = {
    description = "Pleazyng media client for Plex, Jellyfin and Emby";
    homepage = "https://github.com/snapetech-org/pleazyng";
    license = lib.licenses.gpl3Only;
    mainProgram = "pleazyng";
    maintainers = [ lib.maintainers.snapetech ];
    platforms = builtins.attrNames sources;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
