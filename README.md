[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/plik?utm_medium=integration&utm_source=button&utm_campaign=plik)

# Plik on Railway

One-click [Railway](https://railway.com) template for [Plik](https://github.com/root-gg/plik), a self-hosted temporary file upload and sharing system (like WeTransfer).

**Version:** Plik 1.4.3, official image `rootgg/plik:1.4.3@sha256:7b450ff320b3a3f6444ca6fa94c8fde2f5e6eb82d6b9d50bf813ad93e7858f01`.

## What you get

| Service | What it does | Storage |
|---|---|---|
| `Plik` | Plik server: web interface, API, CLI downloads and share links on port 8080, health check `/health` | Railway volume at `/data` (uploaded files and the SQLite metadata database) |

- **Locked by default:** only signed-in users can upload. An `admin` account is created on the first boot with a generated password.
- **Limits:** 1 GB per file, uploads expire after 7 days by default and 30 days at most.
- **Small:** idles at about 10 MB of memory and streams uploads straight to disk, so it runs on Railway's Free plan (0.5 GB). A 300 MB upload peaked at 9 MB of process memory in our test.
- A crash exits non-zero, so Railway's "on failure" restart policy brings it back.

## Variables

| Variable | Default | Notes |
|---|---|---|
| `PLIKD_DEFAULT_ADMIN_LOGIN` | `admin` | Login of the account created on the first boot |
| `PLIKD_DEFAULT_ADMIN_PASSWORD` | generated (`${{secret(24)}}`) | Its password. Only used on the first boot: changing it later does not change the account |
| `PORT` | `8080` | Port Plik listens on |

There is nothing to fill in when you deploy.

## After deploy

1. Open the service's public URL.
2. Sign in as `admin` with the password from the service's `PLIKD_DEFAULT_ADMIN_PASSWORD` variable.
3. Upload a file and share the link. Add accounts for other people in Admin → Users, or create API tokens for the [`plik` CLI](https://root-gg.github.io/plik/features/cli-client.html).

## Changing settings

Every key in Plik's [`plikd.cfg`](https://github.com/root-gg/plik/blob/1.4.3/server/plikd.cfg) can be set as a `PLIKD_` variable in upper snake case ([docs](https://root-gg.github.io/plik/guide/configuration.html)). The start script's defaults (see [`start.sh`](start.sh)) give way to any variable you set:

| Variable | Our default | Example |
|---|---|---|
| `PLIKD_MAX_FILE_SIZE_STR` | `1GB` | `5GB`, `unlimited` |
| `PLIKD_DEFAULT_TTL_STR` | `7d` | `24h` |
| `PLIKD_MAX_TTL_STR` | `30d` | `0` (no limit) |
| `PLIKD_FEATURE_AUTHENTICATION` | `forced` | `default` allows anonymous uploads (not recommended on a public URL) |
| `PLIKD_ENABLE_ARCHIVE_COMPRESSION` | `false` | `true` compresses zip downloads (uses more CPU) |
| `PLIKD_ASSUME_HTTPS` | `true` | Secure cookies and HSTS; Railway always serves HTTPS |

Google, GitHub, OVH or OIDC sign-in and S3, Swift or GCS storage are optional and set the same way (`PLIKD_GOOGLE_API_CLIENT_ID`, `PLIKD_DATA_BACKEND=s3` with `PLIKD_DATA_BACKEND_CONFIG='{...}'`, and so on). Grow the volume in Railway if you expect many large files.

## Updates

The template's service builds from this repo's `main` branch. When we move to a new Plik release (a new pinned version and digest in the `Dockerfile`), Railway shows an "update available" notice on your project, and you choose when to apply it. Read [`CHANGELOG.md`](CHANGELOG.md) first: breaking changes are listed at the top of each entry. Files and accounts stay on the volume.

## Files

- `Dockerfile`: the pinned official image plus the start script.
- `start.sh`: sets Railway-friendly defaults, fixes the volume's ownership, then runs `plikd` as the unprivileged `plik` user.
- `icon.png`: Plik's own favicon (from the 1.4.3 web app), scaled up.

Plik is MIT-licensed by its authors (root-gg). This repo only packages it for Railway.
