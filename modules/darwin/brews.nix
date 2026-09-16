_: [
  # netdoc, a network troubleshooting TUI running interface, DNS, TCP, TLS,
  # HTTP, proxy and path-MTU checks. Homebrew rather than nixpkgs because there
  # is no nixpkgs derivation for it; homebrew-core carries a bottle, so
  # `brew upgrade` tracks releases like any other formula.
  "network-doctor"
]
