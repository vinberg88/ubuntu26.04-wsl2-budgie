# Ubuntu 26.04 Budgie on WSL2

Run the Ubuntu Budgie desktop in a resizable WSLg window on Windows 11.

This repository is made for **Ubuntu 26.04 on WSL2**. It uses native WSL
systemd and WSLg. X410 is not required.

## Quick installation

First update WSL from Windows PowerShell:

```powershell
wsl --update
```

Then open Ubuntu 26.04 and run:

```bash
sudo apt update
sudo apt install -y git
git clone https://github.com/vinberg88/ubuntu26.04-wsl2-budgie.git
cd ubuntu26.04-wsl2-budgie
bash install.sh
```

If the installer enables systemd, close Ubuntu and run this once in Windows
PowerShell:

```powershell
wsl --shutdown
```

Open Ubuntu again and repeat:

```bash
cd ~/ubuntu26.04-wsl2-budgie
bash install.sh
```

## Start the desktop

```bash
budgie26 start
```

To maximize the desktop to the Windows work area:

```bash
budgie26 maximize
```

The launcher remembers both the selected size and whether the window was
maximized.

## Useful commands

| Command | What it does |
| --- | --- |
| `budgie26 start` | Start Budgie |
| `budgie26 stop` | Stop Budgie |
| `budgie26 restart` | Restart Budgie |
| `budgie26 maximize` | Maximize the WSLg window |
| `budgie26 restore` | Restore windowed mode |
| `budgie26 size medium` | Use 1440 x 810 |
| `budgie26 size large` | Use 1600 x 900 |
| `budgie26 size fullhd` | Use 1920 x 1080 |
| `budgie26 doctor` | Check the installation |
| `budgie26 status` | Show session status |
| `budgie26 log` | Show recent logs |

You may also use a custom size, for example:

```bash
budgie26 size 1720x900
budgie26 restart
```

## How it works

Ubuntu 26.04 uses Budgie 10.10 with Labwc for its Wayland session. The launcher
runs the outer Labwc window through WSLg's X11 transport while Budgie itself
continues to use Wayland. This avoids the nested-Wayland pointer crash seen with
the Ubuntu 26.04 wlroots stack.

The session is managed by a transient user systemd service named
`budgie26-wsl.service`.

## Desktop icons

Ubuntu 26.04 currently ships Budgie Desktop View 10.10.2, which automatically
sorts desktop icons. Free icon placement requires Budgie Desktop View 10.10.3
or newer.

## Troubleshooting

Run:

```bash
budgie26 doctor
budgie26 status
budgie26 log
```

If the window opens in an inconvenient position, use:

```bash
budgie26 maximize
```

If an old manually started Budgie or Labwc session is still running, close it
and start the managed session again:

```bash
budgie26 stop
budgie26 start
```

## Scope

This project intentionally targets Ubuntu 26.04 only. Instructions for Ubuntu
24.04 remain in the separate
[`ubuntu24.04-wsl2-systemd-script`](https://github.com/vinberg88/ubuntu24.04-wsl2-systemd-script)
repository.

