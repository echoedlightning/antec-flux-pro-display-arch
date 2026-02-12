# Maintainer: Your Name <your.email@example.com>
pkgname=af-pro-display
pkgver=0.1.2
pkgrel=1
pkgdesc="Service that displays CPU and GPU temperatures on the Antec Flux Pro display"
arch=('x86_64')
url="https://github.com/nishtahir/antec-flux-pro-display"
license=('GPL3')
depends=('gcc-libs' 'systemd')
makedepends=('rust' 'cargo' 'git')
optdepends=('nvidia-utils: for NVIDIA GPU temperature monitoring')
backup=('etc/af-pro-display/config.toml')
source=("$pkgname-$pkgver.tar.gz::https://github.com/nishtahir/antec-flux-pro-display/archive/refs/tags/v$pkgver.tar.gz")
sha256sums=('SKIP')  # Update this with actual checksum after first build

prepare() {
    cd "$srcdir/antec-flux-pro-display-$pkgver"
    
    # Update Cargo.lock if needed
    cargo fetch --locked --target "$(rustc -vV | sed -n 's/host: //p')"
}

build() {
    cd "$srcdir/antec-flux-pro-display-$pkgver"
    
    export RUSTUP_TOOLCHAIN=stable
    export CARGO_TARGET_DIR=target
    cargo build --frozen --release --all-features
}

check() {
    cd "$srcdir/antec-flux-pro-display-$pkgver"
    
    cargo test --frozen --all-features
}

package() {
    cd "$srcdir/antec-flux-pro-display-$pkgver"
    
    # Install binary
    install -Dm755 "target/release/af-pro-display" "$pkgdir/usr/bin/af-pro-display"
    
    # Install systemd service
    install -Dm644 "packaging/af-pro-display.service" "$pkgdir/usr/lib/systemd/system/af-pro-display.service"
    
    # Install udev rules
    install -Dm644 "packaging/99-af-pro-display.rules" "$pkgdir/usr/lib/udev/rules.d/99-af-pro-display.rules"
    
    # Create config directory and install default config
    install -Dm644 "packaging/config.toml" "$pkgdir/etc/af-pro-display/config.toml"
    
    # Install license
    install -Dm644 "LICENSE" "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
    
    # Install README
    install -Dm644 "README.md" "$pkgdir/usr/share/doc/$pkgname/README.md"
}
