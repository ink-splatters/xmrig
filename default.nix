with import <nixpkgs> {} ;
let
  donateLevel = 0;
  inherit (darwin.apple_sdk_11_0.frameworks) Carbon CoreServices OpenCL;
  inherit (llvmPackages_19) libcxxStdenv bintools lld;
in
libcxxStdenv.mkDerivation rec {
  name="xmrig";

  src=./.;

  patches = [
    ./donate-level.patch
  ];

  postPatch = ''
    substituteAllInPlace CMakeLists.txt --replace "-Ofast" "-O3"
    substituteAllInPlace cmake/flags.cmake --replace "-Ofast" "-O3"
    substituteAllInPlace cmake/randomx.cmake --replace "-Ofast" "-O3"
    substituteAllInPlace src/donate.h
    substituteInPlace cmake/OpenSSL.cmake \
      --replace "set(OPENSSL_USE_STATIC_LIBS TRUE)" "set(OPENSSL_USE_STATIC_LIBS FALSE)"
  '';

  nativeBuildInputs = [
    cmake
    ninja
    lld
    bintools
  ];

  buildInputs = [
    libuv
    libmicrohttpd
    openssl
    hwloc
  ] ++  [
    Carbon
    CoreServices
    OpenCL
  ];

  inherit donateLevel;

  installPhase = ''
    runHook preInstall

    install -vD xmrig $out/bin/xmrig

    runHook postInstall
  '';

  # https://github.com/NixOS/nixpkgs/issues/245534
  hardeningDisable = [ "all" ];

  CFLAGS="-O3 -mcpu=apple-m1 -funroll-loops -march=armv8.2-a+fp16  -flto=thin";
  LDFLAGS="-fuse-ld=lld";


  meta = with lib; {
    description = "Monero (XMR) CPU miner";
    homepage = "https://github.com/xmrig/xmrig";
    license = licenses.gpl3Plus;
    mainProgram = "xmrig";
    platforms = platforms.unix;
    maintainers = with maintainers; [ kim0 ];
  };
}
