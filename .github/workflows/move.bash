#!/bin/bash
commit=$(git rev-parse HEAD | head -c 7)
mkdir output
mv build/app/outputs/flutter-apk/app-arm64-v8a-release.apk output/klient-$commit-arm64-v8a.apk
mv build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk output/klient-$commit-armeabi-v7a.apk
mv build/app/outputs/flutter-apk/app-x86_64-release.apk output/klient-$commit-x86_64.apk
mv build/app/outputs/flutter-apk/app-release.apk output/klient-$commit.apk
mv build/app/outputs/bundle/release/app-release.aab output/klient-$commit.aab

tar -czf output/klient-linux-$commit.tar.gz -C build/linux/x64/release/bundle/ .