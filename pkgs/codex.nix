{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  bubblewrap,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "codex";
  version = "0.128.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/@openai/codex/-/codex-${finalAttrs.version}-linux-x64.tgz";
    hash = "sha256-IRYLT2ry9j54ec0iwkwVp4loMybwPL8czumlZtODU3g=";
  };

  nativeBuildInputs = [ makeWrapper ];

  unpackPhase = ''
    runHook preUnpack
    tar -xzf "$src"
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$out/libexec/codex"
    install -m755 package/vendor/x86_64-unknown-linux-musl/codex/codex "$out/libexec/codex/codex"
    install -m755 package/vendor/x86_64-unknown-linux-musl/path/rg "$out/libexec/codex/rg"

    makeWrapper "$out/libexec/codex/codex" "$out/bin/codex" \
      --prefix PATH : "${lib.makeBinPath [ bubblewrap ]}:$out/libexec/codex"

    runHook postInstall
  '';

  meta = {
    description = "Lightweight coding agent that runs in your terminal";
    homepage = "https://github.com/openai/codex";
    license = lib.licenses.asl20;
    mainProgram = "codex";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
