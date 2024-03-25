#!/usr/bin/env bash

shopt -s dotglob nullglob

# (re)create symbolic links
for f in "$(pwd)"/dotfiles/*; do
    ln -sfv "$f" "$HOME"
done

