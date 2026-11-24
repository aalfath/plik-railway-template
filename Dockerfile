# Plik, packaged for Railway. Upstream: https://github.com/root-gg/plik
# Official image, pinned by version and digest. Bump both together (see CHANGELOG.md).
FROM rootgg/plik:1.4.3@sha256:7b450ff320b3a3f6444ca6fa94c8fde2f5e6eb82d6b9d50bf813ad93e7858f01

# The start script runs as root only to fix the Railway volume's ownership,
# then drops to the image's unprivileged "plik" user (UID 1000) to run plikd.
USER root
COPY start.sh /usr/local/bin/plik-start
RUN chmod 755 /usr/local/bin/plik-start

WORKDIR /home/plik/server
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/plik-start"]
