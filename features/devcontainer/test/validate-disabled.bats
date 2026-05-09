#!/usr/bin/env bats
setup() { cd "$TP_DIR"; }

@test "no-devcontainer : .devcontainer/ entièrement absent" {
    [ ! -d .devcontainer ]
}
