#!/bin/zsh
set -e

#  ci_pre_xcodebuild.sh

script_dir="$(cd "$(dirname "$0")" && pwd)"
project_root="${script_dir}/.."
env_file="${project_root}/PennyKeep/Environment.swift"

# Ensure Environment.swift exists (create stub if missing)
if [ ! -f "${env_file}" ]; then
    cat > "${env_file}" <<EOF
struct Env {
    static let OPENAI_API_KEY = "OPENAI_API_KEY_PLACEHOLDER"
}

struct SupabaseEnv {
    static let SUPABASE_URL = "SUPABASE_URL_PLACEHOLDER"
    static let SUPABASE_ANON_KEY = "SUPABASE_ANON_KEY_PLACEHOLDER"
}
EOF
fi

# Process environment variables
typeset -A envValues

# OpenAI API Key
envValues[OPENAI_API_KEY_PLACEHOLDER]=$OPENAI_API_KEY

# Supabase configuration
envValues[SUPABASE_URL_PLACEHOLDER]=$SUPABASE_URL
envValues[SUPABASE_ANON_KEY_PLACEHOLDER]=$SUPABASE_ANON_KEY

# Replace placeholders with actual values
for key in ${(k)envValues}; do
    if [ -n "${envValues[$key]}" ]; then
        sed -i '' -e "s/${key}/${envValues[$key]}/g" "${env_file}"
    fi
done

