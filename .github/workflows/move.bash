#!/bin/bash
commit=$(git rev-parse HEAD | head -c 7)
mkdir output
mv build/app/outputs/flutter-apk/app-arm64-v8a-release.apk output/kosmos-client-$commit-arm64-v8a.apk
mv build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk output/kosmos-client-$commit-armeabi-v7a.apk
mv build/app/outputs/flutter-apk/app-x86_64-release.apk output/kosmos-client-$commit-x86_64.apk
mv build/app/outputs/flutter-apk/app-release.apk output/kosmos-client-$commit.apk
mv build/app/outputs/bundle/release/app-release.aab output/kosmos-client-$commit.aab