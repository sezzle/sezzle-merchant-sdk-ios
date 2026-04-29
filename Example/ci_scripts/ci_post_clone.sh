#!/bin/sh
# Xcode Cloud post-clone script
# Generates Secrets.swift from environment variable

cat > "$CI_PRIMARY_REPOSITORY_PATH/Example/SezzleCheckoutExample/Secrets.swift" <<EOF
enum Secrets {
    static let sezzlePublicKey = "$SEZZLE_PUBLIC_KEY"
}
EOF
