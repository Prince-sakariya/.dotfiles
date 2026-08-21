#!/usr/bin/env zsh

function ff() {
    # ZLE exposes the current editable command line through $BUFFER.
    # Preserve it so the selected file can either be opened directly
    # or inserted into the command currently being constructed.
    local line="$BUFFER"

    # Directories searched by find.
    local -a dirs=(
        ~/robotics
        ~/Documents
        ~/.config
        ~/Desktop
        ~/Downloads
        ~/.ssh
    )

    # Directories excluded from the search.
    # `-prune` prevents find from descending into them.
    local -a no=(
        ~/Documents/0_git/job_applications
    )

    # Custom fzf key bindings.
    #
    # Ctrl-U / Ctrl-D: page up / down
    # Alt-Q through Alt-F: jump to positions 2 through 10
    local opt="ctrl-u:page-up,ctrl-d:page-down,alt-q:pos(2),alt-w:pos(3),alt-e:pos(4),alt-r:pos(5),alt-t:pos(6),alt-a:pos(7),alt-s:pos(8),alt-d:pos(9),alt-f:pos(10)"

    # find generates the candidate list; fzf interactively filters
    # and selects one of those paths.
    #
    # --expect causes fzf to report Ctrl-D or Ctrl-C as the first
    # line of its output when either key terminates the selection.
    local search
    search=$(
        find "${dirs[@]}" \
            -path "${no[1]}" -prune -o \
            -path "${no[2]}" -prune -o \
            -path "${no[3]}" -prune -o \
            -type f -print -readable 2>/dev/null |
        fzf \
            --expect=ctrl-d,ctrl-c \
            --bind="$opt" \
            --scheme=history
    )

    # No output means fzf was cancelled or no result was selected.
    [[ -z "$search" ]] && return

    # When --expect is triggered, fzf outputs:
    #
    #     key
    #     selected-file
    #
    # Extract those two lines separately.
    local key="${search%%$'\n'*}"
    local file="${search#*$'\n'}"

    # Normal Enter produces only the selected file, so there is
    # no separate key line. Detect that form and normalize it.
    if [[ "$key" == "$file" ]]; then
        file="$key"
        key=""
    fi

    case "$key" in
        # Ctrl-D changes into the directory containing the selected
        # file rather than opening or inserting the file.
        ctrl-d)
            cd "$(dirname "$file")"
            zle reset-prompt
            ;;

        # Ctrl-C copies the selected path to the X11 clipboard.
        ctrl-c)
            printf '%s' "$file" | xclip -selection clipboard
            zle reset-prompt
            ;;

        # Enter selects the file normally.
        *)
            if [[ -z "$line" ]]; then
                # Empty command line: use ff as a file opener.
                nvim "$file"
            else
                # Existing command line: insert the selected path
                # as a shell-quoted argument.
                BUFFER="$line '$file'"
                CURSOR=${#BUFFER}
                zle redisplay
            fi
            ;;
    esac
}

# Register ff as a ZLE widget so it can manipulate BUFFER/CURSOR.
zle -N ff

