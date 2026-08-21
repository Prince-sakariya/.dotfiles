#!/usr/bin/env bash

# =============================================================================
# tmux-cht - Interactive cheat-sheet lookup using cht.sh
# =============================================================================
#
# PURPOSE
# -------
# Use fzf to select either a programming language or a command, then query
# cht.sh for examples/documentation. The result is opened in a new tmux window.
#
# SETUP
# -----
# Create two files containing the things you want to search:
#
#   ~/.tmux-cht-languages
#   ~/.tmux-cht-command
#
# Example ~/.tmux-cht-languages:
#
#   bash
#   c
#   cpp
#   javascript
#   python
#   rust
#
# Example ~/.tmux-cht-command:
#
#   curl
#   docker
#   git
#   grep
#   tar
#
# USAGE
# -----
# Run the script from inside a tmux session:
#
#   tmux-cht
#
# 1. fzf displays all entries from both files.
# 2. Select a language or command and press Enter.
# 3. Enter the topic you want to look up.
# 4. A new tmux window opens with the cht.sh result.
#
# LANGUAGE EXAMPLE
# ----------------
# Select:
#
#   python
#
# Then enter:
#
#   list comprehension
#
# The script queries:
#
#   cht.sh/python/list+comprehension
#
# COMMAND EXAMPLE
# ---------------
# Select:
#
#   tar
#
# Then enter:
#
#   extract archive
#
# The script queries:
#
#   cht.sh/tar~extract archive
#
# DEPENDENCIES
# ------------
# The following commands need to be installed and available in $PATH:
#
#   fzf
#   tmux
#   curl
#   less
#
# The script also requires an internet connection because the results come
# from cht.sh.
#
# =============================================================================


# Combine the language and command lists, then use fzf to interactively
# select an entry.
selected=`cat ~/.tmux-cht-languages ~/.tmux-cht-command | fzf`

# Exit cleanly if the user cancels the fzf selection.
if [[ -z $selected ]]; then
    exit 0
fi

# Ask the user what they want to look up.
read -p "Enter Query: " query

# Check whether the selected entry came from the language list.
if grep -qs "$selected" ~/.tmux-cht-languages; then

    # cht.sh uses '+' instead of spaces in language/topic URLs.
    query=`echo $query | tr ' ' '+'`

    # Open a new tmux window, show the URL being queried, and fetch the
    # cheat sheet. The loop keeps the tmux window open after curl exits.
    tmux neww bash -c "echo \"curl cht.sh/$selected/$query/\" & curl cht.sh/$selected/$query & while [ : ]; do sleep 1; done"
else

    # Command cheat sheets use cht.sh's command~query syntax.
    # Pipe the result through less so it can be browsed comfortably.
    tmux neww bash -c "curl -s cht.sh/$selected~$query | less"
fi
