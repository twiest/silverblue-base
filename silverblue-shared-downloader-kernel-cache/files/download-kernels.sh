#!/bin/bash

# Adapted / simplified for my use case from:
#     https://github.com/ublue-os/kernel-cache/tree/main

set -euo pipefail

mkdir /tmp/rpms
cd /tmp/rpms

arch=x86_64
kernel_release=$(skopeo inspect docker://quay.io/fedora/fedora-coreos:stable | jq -r '.Labels["ostree.linux"]')

kernel_major=$(echo "$kernel_release" | cut -d '.' -f 1)
kernel_minor=$(echo "$kernel_release" | cut -d '.' -f 2)
kernel_patch=$(echo "$kernel_release" | cut -d '.' -f 3 | cut -d '-' -f 1)
kernel_headers_patch=1
kernel_distro_magic=$(echo "$kernel_release" | cut -d '.' -f 3 | cut -d '-' -f 2)
kernel_headers_distro_magic=0
kernel_distro=$(echo "$kernel_release" | cut -d '.' -f 4)
kernel_arch=$(echo "$kernel_release" | cut -d '.' -f 5)
kernel_version=${kernel_major}.${kernel_minor}.${kernel_patch}-${kernel_distro_magic}.${kernel_distro}.${kernel_arch}
kernel_headers_version=${kernel_major}.${kernel_minor}.${kernel_headers_patch}-${kernel_headers_distro_magic}.${kernel_distro}.${kernel_arch}

if [ $# -gt 0 ] && [ "$1" == "--debug" ]; then
    echo kernel_major: $kernel_major
    echo kernel_minor: $kernel_minor
    echo kernel_patch: $kernel_patch
    echo kernel_distro_magic: $kernel_distro_magic
    echo kernel_distro: $kernel_distro
    echo kernel_arch: $kernel_arch
    echo kernel_version: $kernel_version
fi

# Download the kernel-headers package (it's in a different path)
kernel_headers_pkg_base="https://kojipkgs.fedoraproject.org/packages/kernel-headers/${kernel_major}.${kernel_minor}.1/0.${kernel_distro}/${kernel_arch}"
echo "Running: dnf download -y ${kernel_headers_pkg_base}/kernel-headers-${kernel_headers_version}.rpm"
dnf download -y "${kernel_headers_pkg_base}/kernel-headers-${kernel_headers_version}.rpm"

# Download the rest of the kernel packages
kernel_pkg_base="https://kojipkgs.fedoraproject.org/packages/kernel/${kernel_major}.${kernel_minor}.${kernel_patch}/${kernel_distro_magic}.${kernel_distro}/${kernel_arch}"
for pkg in kernel kernel-modules kernel-modules-core kernel-modules-extra kernel-devel kernel-devel-matched kernel-uki-virt kernel-debug-core kernel-debug-modules-core; do
  echo "Running: dnf download -y ${kernel_pkg_base}/${pkg}-$kernel_version.rpm"
  dnf download -y "${kernel_pkg_base}/${pkg}-$kernel_version.rpm"
  echo
done

echo --------------------------------------------------------------------------------
echo
echo Results:
echo
pwd
ls -la --color
echo
echo --------------------------------------------------------------------------------
