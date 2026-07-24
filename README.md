# starship

Personal terminal setup for Starship, fonts, and supporting command-line tools on macOS and Linux.

## Install

Run the installer with one command:

```bash
git clone https://git.intp.me/rudgh/starship.git && bash starship/setup.sh
```

The installer uses the current login shell (`zsh`, `bash`, or `fish`). It never resets, deletes, or replaces an existing shell configuration file. If that file already initializes Starship, it is left unchanged.

On supported Linux distributions, it automatically installs curl, unzip, fontconfig, git, ca-certificates, zsh, tar, and gzip before downloading and extracting the Nerd Font and shell tools. Debian/Ubuntu, Arch, Fedora/RHEL, openSUSE, and Alpine package managers are supported. On Linux, it sets the current account login shell to zsh so tmux, autosuggestions, and syntax highlighting use the same shell. The installer verifies the required commands before continuing. This may request your sudo password.
