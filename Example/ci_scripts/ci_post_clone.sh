#!/bin/sh
# Xcode Cloud post-clone script
# Generates Secrets.swift from the SEZZLE_PUBLIC_KEY environment variable
# (set in App Store Connect → Xcode Cloud → workflow → Environment).

set -e

if [ -z "$SEZZLE_PUBLIC_KEY" ]; then
    echo "❌ SEZZLE_PUBLIC_KEY is empty or unset — failing the build."
    echo "   Set it in App Store Connect → Xcode Cloud → Manage Workflows"
    echo "   → workflow → Environment tab, mark as Secret."
    exit 1
fi

# Sanity check the format so a wrong value (e.g. a token) fails loud
if ! echo "$SEZZLE_PUBLIC_KEY" | grep -qE '^sz_pub_[A-Za-z0-9]+$'; then
    echo "❌ SEZZLE_PUBLIC_KEY does not look like a Sezzle public key (expected sz_pub_...)."
    echo "   Got prefix: $(echo "$SEZZLE_PUBLIC_KEY" | head -c 10)..."
    exit 1
fi

cat > "$CI_PRIMARY_REPOSITORY_PATH/Example/SezzleCheckoutExample/Secrets.swift" <<EOF
enum Secrets {
    static let sezzlePublicKey = "$SEZZLE_PUBLIC_KEY"
}
EOF

# Log prefix + suffix so build logs let you verify which key shipped,
# without exposing the full value.
PREFIX=$(echo "$SEZZLE_PUBLIC_KEY" | head -c 10)
SUFFIX=$(echo "$SEZZLE_PUBLIC_KEY" | tail -c 5)
echo "✅ Generated Secrets.swift with key ${PREFIX}...${SUFFIX}"
