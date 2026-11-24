# Changelog

## 1.4.3 (2026-11-24)

First release of the template.

- Plik 1.4.3, official image `rootgg/plik:1.4.3@sha256:7b450ff320b3a3f6444ca6fa94c8fde2f5e6eb82d6b9d50bf813ad93e7858f01`.
- Files and the SQLite metadata database on a Railway volume at `/data`.
- Sign-in required to upload (`PLIKD_FEATURE_AUTHENTICATION=forced`), with an `admin` account created on the first boot from a generated password.
- Defaults: 1 GB per file, 7-day default and 30-day maximum expiry, store-only zip archives, secure cookies, real client IP from `X-Real-IP`, `GOMEMLIMIT` at 80% of the container's memory limit.
- Health check `/health`; plikd exits non-zero on failure, so Railway restarts it.
