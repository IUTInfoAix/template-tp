#!/usr/bin/env bats
setup() { cd "$TP_DIR"; }

@test "no-vscode-config : .vscode/ entièrement absent" {
    [ ! -d .vscode ]
}
