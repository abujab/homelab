#!/usr/bin/env bash

# Activate the HomeLab development environment

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$PROJECT_ROOT/.venv/bin/activate"

echo "HomeLab development environment activated."
echo "Python : $(which python)"
echo "Pip    : $(which pip)"
echo "Ansible: $(which ansible)"
