#!/bin/zsh
set -e

#  ci_pre_xcodebuild.sh

script_dir="$(cd "$(dirname "$0")" && pwd)"
project_root="${script_dir}/.."
env_file_path="${project_root}/PennyKeep/Environment.swift"

# Ensure Environment.swift exists (create stub if missing)
if [ ! -f "${env_file_path}" ]; then
    cat > "${env_file_path}" <<EOF
struct Env {
    static let OPENAI_API_KEY = "OPENAI_API_KEY_PLACEHOLDER"
}
EOF
fi

typeset -A envValues

envValues[OPENAI_API_KEY_PLACEHOLDER]=$OPENAI_API_KEY

for key in ${(k)envValues}; do
    sed -i '' -e "s/${key}/${envValues[$key]}/g" "${env_file_path}"
done

