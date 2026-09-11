# TODO

All 2026-09-07 change-sets below are committed and pushed to `origin/trunk`
(six commits: `--shell` bash/fish parity, bash bug fixes, fish/functions
symlink migration, mybootstrap_cross_distro.sh removal, the ssh_agent
rebuild, and a TODO.md doc-only follow-up). The 2026-09-08 `--mod`
comma-list change below is still uncommitted. What's left otherwise is
live-deployment follow-through plus the new VM test lab.

## Live deployment

- [ ] `./bootstrap.sh --shell bash` has never been run for real on this
      machine — live `~/.bashrc`/`.bash_aliases`/`.bash_functions` still run
      the old pre-refactor style, not the repo's dispatcher-based rewrite.
      Run it (ideally `--dry-run` first) when ready to deploy.
- [ ] Once satisfied the `fish/functions` → repo symlink is working, delete
      the old live backup at `~/.config/fish/functions.bak_20260907_125015`.

## Uncommitted (2026-09-08)

- [ ] `--mod` now accepts a comma-separated list (`--mod a,b,c`) in addition
      to the existing repeatable-flag form (`--mod a --mod b`) — both combine
      and dedupe. Implemented via a new `add_selected_modules()` helper in
      `parse_args()`. Verified with `bash -n` and dry-run tests. Not yet
      committed — `git diff bootstrap.sh` has the change sitting in the
      working tree.

## VM test lab (libvirt/virt-manager)

Set up 2026-09-08 to give `bootstrap.sh` real per-distro test targets instead
of only ever running against this one CachyOS/pacman machine.

- Two libvirt storage pools under `qemu:///system` (the connection
  virt-manager's default "QEMU/KVM" view uses):
  `isos` → `~/Downloads/isos` (existing ISO library), `vmdisks` → `~/VMs`
  (VM disk images).
- Five VMs, 4GB RAM / 2 vCPU / 20GB qcow2 disk each, one per package-manager
  branch in `detect_pkg_manager()`, all using QEMU user-mode networking
  (`--network user`, not the libvirt-managed default NAT network — see known
  issue below) so they still get outbound internet during install:
  - `bootstrap-arch` — Arch Linux (pacman)
  - `bootstrap-debian13` — Debian 13 (apt, systemd)
  - `bootstrap-antix` — antiX 23.1 (apt, **no systemd** — this is the
    "actual antiX box" the ssh_agent section below has been waiting on)
  - `bootstrap-fedora44` — Fedora Server 44 (dnf5)
  - `bootstrap-opensuse16` — openSUSE Leap 16.0 (zypper)
- [ ] **None of the 5 VMs have an OS installed yet** — they're only sitting
      at their installer boot screens (no autoinstall/kickstart/preseed was
      configured). Walk each through its interactive install via
      virt-manager, then use them to actually run `bootstrap.sh` per distro.
- [ ] Once `bootstrap-antix` is installed, run `--mod ssh_agent` on it for
      real — this is the concrete way to close the "actual antiX box
      untested" item in the ssh_agent section below.
- [ ] **Known host bug, unfixed:** `qemu:///system`'s default NAT network
      can't start — `virsh net-start default` fails with
      `error creating bridge interface virbr0: Operation not permitted`,
      even though `libvirtd` runs as root with a full capability set and a
      plain `sudo ip link add virbr0 type bridge` succeeds outside libvirtd.
      Restarting `libvirtd` didn't fix it; root cause not found (not
      AppArmor/SELinux/capability-bounding-set as far as could be checked
      in-session — see git blame/session history around 2026-09-08 for the
      full debugging trail). Worked around via QEMU user-mode networking for
      these 5 VMs, which needs no bridge. Only matters if/when NAT-bridged
      networking (inter-VM comms, port forwarding, DHCP-visible VMs) is
      actually needed — reported as Claude Code feedback but the libvirt bug
      itself is still open on this host.
- Gotcha for any future `virsh`/`virt-install` work on this host: the
  default connection resolved to `qemu:///session` (unprivileged, per-user
  driver) rather than `qemu:///system` (what virt-manager shows by
  default) when no `--connect`/`-c` was given. Always pass
  `-c qemu:///system` explicitly, or the VMs/pools land somewhere virt-manager
  won't show them.

## Known bash bugs (fixed 2026-09-07, commit a901aee)

- [x] `wz()` in `bash/.bash_functions` was a broken stub referencing
      `install_warzone2100`, which never existed anywhere (fish's real
      implementation is just `wz.fish`). Removed the stub per user decision —
      fish stays canonical for this one, and its Ubuntu-specific
      `get-dependencies_linux.sh ubuntu` call is arguably its own latent bug
      there, not something worth porting into bash on this Arch/CachyOS box.
- [x] `img resize` in `bash/.bash_functions` had a temp-file collision bug:
      `/tmp/tmp_$.$ext` → `/tmp/tmp_$$.$ext` (missing PID for uniqueness).
- [x] `local` used outside any function body in `bash/scripts/bmedia`,
      `bimg`, `bfileops`, and `butils` — silently broke variable assignment
      at runtime (confirmed: `local` outside a function fails and leaves the
      var empty, it doesn't just error) for `compress`/`resize`/`clean`/
      `favicon`/`changecase`/`duplicate`/`swap`/`random`/`noempties`/`guid`,
      etc. Fixed by dropping `local` (these are standalone one-shot scripts,
      not sourced functions, so script-global scope is fine and matches the
      style already used elsewhere in the same files). Two spots
      (`bfileops` orig_lines/new_lines and orig_size/new_size, plus one bare
      `output`) were bare declarations with no assignment — those became
      stray command invocations after the mechanical `local` strip, so they
      were deleted outright rather than left as dead lines. `bsys` and
      `barchive` were unaffected (never used `local` at top level).

**Investigated, turned out not to be bugs** (audit false positives — behavior
matches fish intentionally, left as-is):
- `wav2mp3()`/`ogg2mp3()` duplicates — fish's `audioconv.fish` does the same
  thing under a "backward compatibility wrappers" comment; bash mirrors it.
- `plugdummy()`/`dummyfile()` argument swap — fish's `plugdummy.fish`
  deliberately swaps args vs `dummyfile.fish`; bash matches. Added an inline
  comment in `bash/.bash_functions` noting it's intentional.

## `ssh_agent` module: rebuilt for cross-system parity (2026-09-07, commits d445e51 + 6c4da92)

Root cause of the original "live `~/.ssh/config` doesn't exist despite units
looking installed" finding: **`bootstrap.sh` had a bash bad-substitution bug
(`${#AUR_PKGS[@]:-0}`, invalid syntax — array-length doesn't take a `:-`
default) that killed every real (non-`--dry-run`) run on this pacman/CachyOS
machine right after package installation, before it ever reached
`scripts_bin`/`dotfiles_bashrc`/`dotfiles_fish`/`ssh_agent`/`vim_ycm`/`rust`.**
Fixed (`${#AUR_PKGS[@]}`). This means `--shell bash` and `ssh_agent` (and
anything else downstream in `execute_plan`) likely never actually ran to
completion on this machine before, regardless of what was selected.

What "the `ssh-agent.service` units looked installed and enabled" turned out
to mean: that was the distro-packaged OpenSSH `ssh-agent.service`/`.socket`
(same unit *names*, different files, at `/usr/lib/systemd/user/`) — not the
repo's own units, which were never deployed to `~/.config/systemd/user/`.
The agent actually in daily use here is XFCE's own: `xfce4-session` has a
compiled-in "launch ssh-agent on startup" feature (xfconf key
`/startup/ssh-agent/enabled`, on by default whenever `gnome-keyring-daemon`
isn't present) that spawns `ssh-agent -s` and reparents it to init.

- [x] Simplified `ssh/config` and `systemd/user/ssh-add.service` to a single
      key (`id_ed25519`) — dropped the `github-didactic-waddle` /
      `id_ed25519_didactic_waddle` split-key design, which referenced a key
      that was never generated and isn't exercised anyway (this repo's own
      `origin` remote is HTTPS, not SSH).
- [x] Added `detect_init_system()` to `bootstrap.sh` (checks
      `/run/systemd/system`) — `detect_pkg_manager` alone can't distinguish
      e.g. antiX (apt, no systemd) from Debian/Ubuntu (apt, systemd), and the
      module was systemd-only before this.
- [x] `ssh_agent`'s execute step now: (1) always downloads `ssh/config`;
      (2) if `xfce4-session` is present, disables its built-in ssh-agent
      auto-launch via `xfconf-query` so it stops racing our agent for
      `SSH_AUTH_SOCK` — this guard runs regardless of init system, since
      antiX has an XFCE spin too; (3) on systemd hosts, deploys the real
      `systemd/user/ssh-agent.service`/`ssh-add.service` as before; (4) on
      non-systemd hosts, downloads the new `ssh/agent-init.sh` (POSIX sh) to
      `~/.ssh/` and idempotently wires it into `~/.bash_profile`, plus the
      new `fish/functions/ssh_agent_ensure.fish` wired into
      `~/.config/fish/config.fish` if fish dotfiles are already deployed.
      Both fallback scripts reuse any already-reachable agent before
      starting + caching a new one (`~/.ssh/agent-env` / `agent-env.fish`).
      Verified: dry-run plan output on both branches, real execution against
      a fake `$HOME` with `detect_init_system` forced to "other" (confirms
      file writes + idempotent rc-file wiring — no duplicate marker on a
      second run — for both bash and fish gates), and syntax-checked
      (`bash -n`, `sh -n`).
- [x] Pushed to `origin/trunk` — a real run of `--mod ssh_agent` on a
      non-systemd host can now fetch `ssh/agent-init.sh` /
      `ssh_agent_ensure.fish` without 404ing.
- [x] DE-collision guard extended beyond XFCE (2026-09-07). Correction to the
      original premise: GNOME/MATE/Cinnamon do **not** collide via a
      `gnome-keyring-daemon` ssh `.desktop` autostart entry — that component
      was disabled/removed from gnome-keyring in 1:46+ and moved into gcr4's
      `gcr-ssh-agent`, which ships as a **socket-activated systemd user
      unit** (`gcr-ssh-agent.socket`/`.service`), not an autostart file.
      Confirmed on this machine: `gnome-keyring-daemon --help` (v50) no
      longer lists an `ssh` component, and `gcr-ssh-agent.socket` exists
      (pulled in transitively even on this XFCE box). `bootstrap.sh`'s
      systemd branch now disables `gcr-ssh-agent.socket`/`.service` if
      present, alongside the existing xfconf guard for xfce4-session. KDE's
      ssh-agent (`gpg-agent.conf`'s `enable-ssh-support`) stays unguarded —
      confirmed still opt-in, not on by default. LXDE/LXQt/Deepin/Pantheon
      behavior still unconfirmed but lower priority (none are known to bundle
      gcr4's agent by default).
- [x] Live-tested `--mod ssh_agent` for real on this machine (2026-09-07),
      via a scratch copy of `bootstrap.sh` with `RAW_BASE` pointed at a
      `python3 -m http.server` serving the local working tree (real
      `origin/trunk` is still stale/unpushed, so a normal run would have
      re-downloaded the old split-key `ssh/config` and the now-deleted
      `ssh-add.service`). Confirmed: `~/.ssh/config` deploys correctly,
      xfconf guard and the new `gcr-ssh-agent` guard both fire, and
      `ssh-agent.service` enables/starts cleanly at
      `/run/user/1000/ssh-agent.socket` (matching what `fish/config.fish`
      expects).
- [x] **Found and fixed a real bug via the live test:** `ssh-add.service`
      failed every time — `id_ed25519` is passphrase-protected, and a
      systemd oneshot has no TTY and no `ssh-askpass` binary installed to
      prompt through it (`ssh_askpass: exec(/usr/lib/ssh/ssh-askpass): No
      such file or directory`). Since it had never been deployed before
      today (see root-cause section above), this was never caught. Per user
      decision, **dropped `ssh-add.service` entirely** — `ssh/config`
      already has `AddKeysToAgent yes`, which adds the key lazily and
      interactively (real terminal, real prompt) the first time it's
      actually used, making the eager unattended `ssh-add` redundant and
      unreliable. Removed `systemd/user/ssh-add.service` from the repo and
      all references in `bootstrap.sh` (download loop, `systemctl --user
      enable --now ssh-add`, `plan_ssh_agent`, `--help-module ssh_agent`
      text). Live system cleaned up to match: unit file, its
      `default.target.wants` symlink, and its failed unit state all removed;
      `ssh-agent.service` alone remains enabled and running.
- [ ] Still untested: an actual antiX (or other non-systemd) box — see the
      `bootstrap-antix` VM in the "VM test lab" section above, built
      2026-09-08 specifically for this.
