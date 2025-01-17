#!/bin/bash
echo "PKG_CONFIG_PATH=$HOME/ffmpeg_build/lib/pkgconfig:$PKG_CONFIG_PATH" >> $GITHUB_ENV
echo "PATH=$HOME/ffmpeg_build/bin:$PATH" >> $GITHUB_ENV
echo "LD_LIBRARY_PATH=$HOME/ffmpeg_build/lib:$LD_LIBRARY_PATH" >> $GITHUB_ENV

sudo apt-get update
sudo apt-get install -y libdav1d-dev libaom-dev libfdk-aac-dev libvpx-dev libopus-dev libx264-dev libx265-dev zip meson \
  nasm autoconf autogen automake libtool libfreetype6-dev libfontconfig1-dev libfribidi-dev libssl-dev libpulse-dev alsa-source libasound2-dev \
  build-essential crossbuild-essential-arm64 wget

curl https://sh.rustup.rs -sSf | sh -s -- -y

git clone --depth 1 https://github.com/quietvoid/dovi_tool
cd dovi_tool || exit
rm -rf ffmpeg_build.user && mkdir ffmpeg_build.user || exit
source "$HOME/.cargo/env" # for good measure

cd dolby_vision
cargo install cargo-c
cargo cinstall --release \
--prefix="../ffmpeg_build.user" \
--libdir="../ffmpeg_build.user"/lib \
--includedir="../ffmpeg_build.user"/include
cd ../ffmpeg_build.user || exit
sudo cp ./lib/* /usr/local/lib/ -r || exit
sudo cp ./include/* /usr/local/include/ -r
cd

git clone --depth 1 https://github.com/quietvoid/hdr10plus_tool
cd hdr10plus_tool
rm -rf ffmpeg_build.user && mkdir ffmpeg_build.user || exit
source "$HOME/.cargo/env" # for good measure

cd hdr10plus || exit
RUSTFLAGS="-C target-cpu=native" cargo cinstall --release \
      --prefix="../ffmpeg_build.user" \
      --libdir="../ffmpeg_build.user"/lib \
      --includedir="../ffmpeg_build.user"/include
cd ../ffmpeg_build.user || exit
sudo cp ./lib/* /usr/local/lib/ -r || exit
sudo cp ./include/* /usr/local/include/ -r
cd

git clone --depth 1 https://github.com/xiph/ogg.git
cd ogg
./autogen.sh
./configure --prefix="$HOME/ffmpeg_build" --disable-shared  --build=aarch64-linux-gnu
make -j$(nproc)
make install
cd

git clone --depth 1 https://github.com/xiph/vorbis.git
cd vorbis
./autogen.sh
PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" \
  ./configure --prefix="$HOME/ffmpeg_build" \
  --build=aarch64-linux-gnu \
  --with-ogg="$HOME/ffmpeg_build" \
  --disable-shared
make -j$(nproc)
make install
cd


wget https://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz
tar xzf lame-3.100.tar.gz
cd lame-3.100

# Run configure with modified flags
./configure --prefix="$HOME/ffmpeg_build" \
  --enable-nasm \
  --disable-shared

make -j$(nproc)
make install
cd


git clone --depth 1 https://github.com/adah1972/libunibreak.git
cd libunibreak
./autogen.sh
PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure \
  --prefix="$HOME/ffmpeg_build" \
  --build=aarch64-linux-gnu \
  --disable-shared \
  --enable-static
make -j$(nproc)
make install
cd

git clone --depth 1 https://github.com/harfbuzz/harfbuzz.git
cd harfbuzz
mkdir build && cd build
meson setup --prefix="$HOME/ffmpeg_build" --default-library=static ..
ninja 
ninja install
cd


git clone --depth 1 https://github.com/libass/libass.git
cd libass
./autogen.sh
PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig:$PKG_CONFIG_PATH" ./configure \
  --prefix="$HOME/ffmpeg_build" \
  --disable-shared \
  --enable-static \
  --build=aarch64-linux-gnu 
make -j$(nproc)
make install
cd

git clone --depth 1 https://gitlab.com/AOMediaCodec/SVT-AV1.git
cd SVT-AV1/Build
PATH="$HOME/bin:$PATH" cmake -G "Unix Makefiles" \
  -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" \
  -DCMAKE_SYSTEM_PROCESSOR=aarch64 \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_DEC=OFF \
  -DENABLE_AVX512=OFF \
  -DCOVERAGE=OFF -DLIBDOVI_FOUND=1 \
  -DLIBHDR10PLUS_RS_FOUND=1 \
  -DBUILD_SHARED_LIBS=OFF ..
PATH="$HOME/bin:$PATH" make -j$(nproc)
make install
cd


wget -O x265.tar.bz2 https://bitbucket.org/multicoreware/x265_git/get/master.tar.bz2
tar xjvf x265.tar.bz2
cd multicoreware*/build/linux
PATH="$HOME/bin:$PATH" cmake -G "Unix Makefiles" \
  -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" \
  -DCMAKE_SYSTEM_PROCESSOR=aarch64 \
  -DENABLE_SHARED=off \
  -DHIGH_BIT_DEPTH=ON ../../source
PATH="$HOME/bin:$PATH" make -j$(nproc)
make install
cd

git clone --depth 1 https://github.com/ultravideo/kvazaar.git
cd kvazaar 
./autogen.sh
PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" \
  ./configure --prefix="$HOME/ffmpeg_build" \
  --build=aarch64-linux-gnu \
  --bindir="$HOME/bin" \
  --enable-static \
  --disable-shared
PATH="$HOME/bin:$PATH" make -j$(nproc)
make install
cd


git -C x264 pull 2> /dev/null || git clone --depth 1 https://code.videolan.org/videolan/x264.git
cd x264
PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" \
  ./configure --prefix="$HOME/ffmpeg_build" \
  --build=aarch64-linux-gnu \
  --bindir="$HOME/bin" \
  --enable-static \
  --enable-pic
PATH="$HOME/bin:$PATH" make -j$(nproc)
make install
cd 

git -C opus pull 2> /dev/null || git clone --depth 1 https://github.com/xiph/opus.git
cd opus
./autogen.sh
./configure --prefix="$HOME/ffmpeg_build" --disable-shared  --build=aarch64-linux-gnu 
make -j2
make install
cd 


git -C fdk-aac pull 2> /dev/null || git clone --depth 1 https://github.com/mstorsjo/fdk-aac
cd fdk-aac
autoreconf -fiv
./configure --prefix="$HOME/ffmpeg_build" --disable-shared   --build=aarch64-linux-gnu 
make -j$(nproc)
make install
cd


git -C dav1d pull 2> /dev/null || git clone --depth 1 https://code.videolan.org/videolan/dav1d.git
mkdir -p dav1d/build
cd dav1d/build
meson setup -Denable_tools=false \
  -Denable_tests=false \
  --default-library=static .. \
  --prefix "$HOME/ffmpeg_build" \
  --libdir="$HOME/ffmpeg_build/lib"
ninja 
ninja install
cd


git -C libvpx pull 2> /dev/null || git clone --depth 1 https://chromium.googlesource.com/webm/libvpx.git
cd libvpx
PATH="$HOME/bin:$PATH" ./configure \
  --build=aarch64-linux-gnu \
  --prefix="$HOME/ffmpeg_build" \
  --disable-examples \
  --disable-unit-tests \
  --enable-vp9-highbitdepth \
  --as=yasm
PATH="$HOME/bin:$PATH" make -j$(nproc)
make install
cd


git -C aom pull 2> /dev/null || git clone --depth 1 https://aomedia.googlesource.com/aom
mkdir -p aom_build
cd aom_build
PATH="$HOME/bin:$PATH" cmake -G "Unix Makefiles" \
  -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" \
  -DCMAKE_SYSTEM_PROCESSOR=aarch64 \
  -DENABLE_TESTS=OFF \
  -DENABLE_NASM=on ../aom
PATH="$HOME/bin:$PATH" make -j$(nproc)
make install
cd


git clone https://git.ffmpeg.org/ffmpeg.git ffmpeg
cd ffmpeg
git checkout master
export LD_LIBRARY_PATH+=":/usr/local/lib"
PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure \
  --build=aarch64-linux-gnu \
  --extra-cflags="-I$HOME/ffmpeg_build/include" \
  --extra-ldflags="-L$HOME/ffmpeg_build/lib" \
  --extra-libs="-lpthread -lm" \
  --enable-gpl \
  --enable-alsa\
  --enable-libpulse\
  --enable-libx264 \
  --enable-libx265 \
  --enable-libkvazaar \
  --enable-libvpx \
  --enable-libfdk-aac \
  --enable-libmp3lame \
  --enable-libopus \
  --enable-libvorbis \
  --enable-libass \
  --enable-libsvtav1 \
  --enable-libaom \
  --enable-libdav1d \
  --enable-nonfree \
  --enable-static \
  --pkg-config-flags="--static" \
  --disable-shared
make -j$(nproc)
./ffmpeg -version


cd ffmpeg
mkdir ffmpeg-package
cp ./ffmpeg ffmpeg-package/
cp ./ffprobe ffmpeg-package/
zip -r ../ffmpeg-package.zip ffmpeg-package

