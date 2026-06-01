# Base image for devcontainer with Java/JavaFX support.
# On épingle explicitement la LTS (24.04 / noble) au lieu du tag flottant
# `:ubuntu` : ce dernier a glissé vers Ubuntu 26.04 « Resolute » à sa sortie
# (avril 2026), ce qui rendait la construction de la feature desktop-lite
# intermittente (miroirs archive.ubuntu.com encore mal synchronisés sur une
# LTS fraîche + téléchargement noVNC/websockify depuis GitHub). Figer la base
# rend le build reproductible et déterministe.
FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

# Install dependencies for JavaFX GUI applications.
# xvfb fournit un display virtuel pour ./mvnw test si l'utilisateur
# désactive le feature desktop-lite (qui démarre déjà son propre Xvfb).
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
        libgtk-3-0 \
        libglu1-mesa \
        libxrender1 \
        libxtst6 \
        libxi6 \
        xvfb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
