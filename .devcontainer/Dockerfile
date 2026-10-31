# The build environment for everything here that builds: mforth, the lab's
# exercises and the slide examples. The tools they use and nothing else.
#
# Codespaces builds this through devcontainer.json next to it. lab/docker-shell
# builds the same file for anyone running the lab on their own machine, so
# both places get the same nasm, the same clang and the same gdb. To build
# mforth in it, see the README at the repository root.
#
# python3 is here only to serve the lab pages; git is here because VS Code
# expects to find it in a codespace.
FROM ubuntu:26.04

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        nasm clang gdb make python3 git ca-certificates less \
 && rm -rf /var/lib/apt/lists/*
