# Dotfiles

Personal Linux configuration managed with [GNU Stow](https://www.gnu.org/software/stow/).

The repository is organized into Stow packages. Each package contains files that should be symlinked into `$HOME`.

## Structure

The main Stow packages are:

```text
bin/
tmux/
uwuntu/
personal/
i3/
zsh/
```

The packages currently configured by default are:

```text
bin,tmux,uwuntu,personal,i3,zsh
```

The list is controlled by the `STOW_FOLDERS` environment variable.

## Installation

The easiest way to install the environment is:

```bash
~/.dotfiles/ubuntu
```

The `ubuntu` script sets the default environment if the required variables are not already defined:

```text
DOTFILES=$HOME/.dotfiles
STOW_FOLDERS=bin,i3,tmux,uwuntu,zsh
```

It then runs the main `install` script.

> Note: if `STOW_FOLDERS` is already exported in your shell configuration, that value takes precedence over the default in `ubuntu`.

## Install / Update

The main installer is:

```bash
~/.dotfiles/install
```

It:

1. Changes into `$DOTFILES`.
2. Splits `STOW_FOLDERS` on commas.
3. Removes existing Stow links for each package.
4. Re-applies each package with GNU Stow.

In other words, it effectively performs:

```bash
stow -D <package>
stow <package>
```

for every configured package.

This makes the installer safe to run repeatedly when updating the dotfiles.

## Clean the Environment

To remove the Stow-managed symlinks:

```bash
~/.dotfiles/clean-env
```

This runs:

```bash
stow -D <package>
```

for every configured package.

It removes the links created by Stow but does not remove the actual files from this repository.

## Environment Variables

### `DOTFILES`

Path to the root of the dotfiles repository.

Default:

```bash
$HOME/.dotfiles
```

Example:

```bash
export DOTFILES="$HOME/.dotfiles"
```

### `STOW_FOLDERS`

Comma-separated list of Stow packages to install.

Example:

```bash
export STOW_FOLDERS="bin,tmux,uwuntu,personal,i3,zsh"
```

Adding or removing a package from this variable changes what `install` and `clean-env` operate on.

## GNU Stow

This repository expects [GNU Stow](https://www.gnu.org/software/stow/) to be installed.

On Ubuntu:

```bash
sudo apt install stow
```

Stow creates symlinks from the files inside each package to their corresponding locations in `$HOME`.

For example, a package containing:

```text
zsh/.zshrc
```

can be installed by Stow as:

```text
~/.zshrc -> ~/.dotfiles/zsh/.zshrc
```

## Scripts

### `ubuntu`

Bootstrap entry point intended for an Ubuntu installation.

```bash
~/.dotfiles/ubuntu
```

Sets defaults for `DOTFILES` and `STOW_FOLDERS` when they are not already defined, then runs `install`.

### `install`

Applies all configured Stow packages.

```bash
~/.dotfiles/install
```

### `clean-env`

Removes all configured Stow packages.

```bash
~/.dotfiles/clean-env
```

## Typical Workflow

After cloning the repository:

```bash
git clone <repository> ~/.dotfiles
cd ~/.dotfiles
./ubuntu
```

After changing dotfiles:

```bash
~/.dotfiles/install
```

To remove the environment's Stow-managed links:

```bash
~/.dotfiles/clean-env
```

## Adding a New Package

Create a new directory at the repository root:

```text
my-package/
```

Put the files inside it according to where they should appear relative to `$HOME`.

For example:

```text
my-package/
└── .config/
    └── something/
        └── config
```

Add the package to `STOW_FOLDERS`:

```bash
export STOW_FOLDERS="bin,tmux,uwuntu,personal,i3,zsh,my-package"
```

Then run:

```bash
~/.dotfiles/install
```

GNU Stow will create the appropriate symlinks in your home directory.

