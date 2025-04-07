#!/usr/bin/bash

## Inspired from https://gist.github.com/theaog/e8923142320f57d2157dcb28b5cc6b0d

set -e

tmp=$(mktemp -d)
pushd "$tmp" || exit 1

function cleanup {
    popd || exit 1
    rm -rf "$tmp"
}
trap cleanup EXIT

version=$(go version |cut -d' ' -f3)
release=$(wget -qO- "https://golang.org/VERSION?m=text" | grep -E '^go[1-9]\.[0-9]+\.[0-9]+$')

[ -z "$release" ] && {
    echo "Failed to retrieve last release"
    exit 1
}

release_file="${release}.linux-amd64.tar.gz"
update=true

if [[ $version == "$release" ]]; then
    echo "Local Go version ${release} is the latest."
    update=false
else
    echo "Local Go version ${version}, new release ${release} is available."
fi

$update && {
    echo "Downloading https://go.dev/dl/$release_file ..."
    curl -OL https://go.dev/dl/"$release_file" || exit 1

    if type go &> /dev/null; then
        goroot=$(go env |grep GOROOT |cut -d'=' -f2 |tr -d '"')
        [ -z "$goroot" ] && {
            echo "Failed to retrieve last GOROOT env vara=iable"
            exit 1
        }

        [ -e "$goroot" ] && {
            echo "removing folder $goroot"
            sudo rm -irf "$goroot"
        }
    else
        goroot=/usr/local/go
    fi

    sudo tar -C "${goroot//go}" -xzf "$release_file"

    version=$(go version |cut -d' ' -f3)
    echo "local Go version is $version (latest)"

    echo "installing latest Go Tools"
    go install golang.org/x/tools/cmd/goimports@latest
    go install  golang.org/x/tools/gopls@latest
}

# Update binaries installed by "go install" with goroutines.
go install github.com/nao1215/gup@latest
gup update
