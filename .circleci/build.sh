#!/usr/bin/env bash

cd /

#Fetch sources

git clone --depth 1 https://github.com/offset1313/M49 wahoo
git clone --depth 1 https://github.com/kdrag0n/proton-clang.git pclang
git clone --depth 1 git://github.com/CurioussX13/AnyKernel3 -b mido ak3

# Set Build Env
IMG=/wahoo/out/arch/arm64/boot/Image.gz-dtb
BID=$(openssl enc -base64 -d <<< OTk0MzkyMzY3OkFBRk9ZUS04aXZKUklLQTR2MEJQTGJuV3B0M1hWejNJSXFz )
GID=$(openssl enc -base64 -d <<< LTEwMDEzMTM2MDAxMDY= )
BDT=$(date +"%h-%d-%s")
TOOL_VERSION=$("/pclang/bin/clang" --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')

export ARCH=arm64
export CLANG_PATH=/pclang/bin
export PATH=${CLANG_PATH}:${PATH}
export LD_LIBRARY_PATH="/pclang/bin/../lib:$PATH"

function sendInfo() 
{
 curl -s -X POST https://api.telegram.org/bot"$BID"/sendMessage -d chat_id="$GID" -d "parse_mode=HTML" -d text="$(
  for POST in "${@}"; do
   echo "${POST}"
    done
     )" 
}

function sendLog() 
{
 curl -F chat_id="${GID}" -F document=@/build.log https://api.telegram.org/bot"$BID"/sendDocument
}

function sendZip()
{
 cd /ak3 || exit
 ZIP=$(echo *.zip)
 curl -F chat_id="${GID}" -F document="@$ZIP"  https://api.telegram.org/bot"${BID}"/sendDocument
}

function zipper()
{
 cp "${IMG}" /ak3
 cd /ak3 || exit 
 make -j16
 mv Thy-Kernel.zip ThyG-"${BDT}".zip
}
function success() 
{
 sendInfo "<b>Commit: </b><code>$(git --no-pager log --pretty=format:'"%h - %s (%an)"' -1)</code>" \
          "<b>Compile Time: </b><code>$((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)</code>" \
          "<b>Toolchain:</b><code>${TOOL_VERSION}</code>" \
          "<b>proJTHy Success</b>"
 sendLog
}

function failed() 
{
 sendInfo "<b>Commit:</b><code>$(git --no-pager log --pretty=format:'"%h - %s (%an)"' -1)</code>" \
          "<b>ProJThy Failed</b>" \
          "<b>Total Time Elapsed: </b><code>$((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds.</code>"
 sendLog
 exit 1;
 }

function compile() 
{

		cd /wahoo || exit
		START=$(date +"%s")
		make ARCH=arm64 mido_defconfig O=out
		PATH="/pclang/bin/:${PATH}" \
		make O=out -j16 &> /build.log \
			CC=clang \
			CLANG_TRIPLE=aarch64-linux-gnu- \
			CROSS_COMPILE=aarch64-linux-gnu- \
			CROSS_COMPILE_ARM32=arm-linux-gnueabi-
		


if ! [ -a "$IMG" ] ; 
then																		
   END=$(date +"%s")
   DIFF=$((END - START))
   failed  

fi
  END=$(date +"%s")
  DIFF=$((END - START))
  success
  zipper
  sendZip
}

compile
