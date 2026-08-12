#!/usr/bin/env bash
# Environment template for the Confluence second brain.
#
# Copy, fill in, and source it from your shell profile:
#   cp scripts/env.example.sh ~/.confluence-brain.env
#   $EDITOR ~/.confluence-brain.env
#   echo 'source ~/.confluence-brain.env' >> ~/.zshrc
#
# Keep the filled-in copy OUTSIDE this repo. The token below is a credential:
# on Confluence Server/Data Center a PAT bypasses SSO entirely and carries your
# full read scope. Treat it like your password. Never commit it.
#
# Pick ONE of the two blocks below and leave the other commented out.

# ---------------------------------------------------------------- Cloud ----
# export CONFLUENCE_URL="https://yoursite.atlassian.net"
# export CONFLUENCE_USERNAME="you@example.com"
# export CONFLUENCE_API_TOKEN="..."          # id.atlassian.com > API tokens
# export CONFLUENCE_SPACE_URL="https://yoursite.atlassian.net/wiki/spaces/KEY"

# ------------------------------------------------ Server / Data Center ----
# URL must include the context path if your instance has one (many do).
# Check your browser: https://wiki.example.com/confluence/display/KEY
#                     ^--------- CONFLUENCE_URL ---------^
# export CONFLUENCE_URL="https://wiki.example.com/confluence"
# export CONFLUENCE_PAT="..."                # profile > Personal Access Tokens
# export CONFLUENCE_SPACE_URL="https://wiki.example.com/confluence/display/KEY"

# --------------------------------------------------------------- Both ----
# Comma-separated space keys the MCP server is allowed to touch. Optional but
# recommended: it narrows blast radius if the agent goes exploring.
# export CONFLUENCE_SPACES="KEY1,KEY2"

# Only if your instance uses a certificate not in the OS trust store.
# Do not set this reflexively — it disables TLS verification.
# export CONFLUENCE_SSL_VERIFY="false"
