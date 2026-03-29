#!/usr/bin/env bash

set -euo pipefail

format_mb() {
  local mb="$1"

  if (( mb >= 1024 )); then
    awk "BEGIN { printf \"%.2f GB\", ${mb}/1024 }"
  else
    printf "%s MB" "$mb"
  fi
}

print_linux_ram() {
  local total_mb available_mb used_mb

  total_mb=$(awk '/MemTotal/ { printf "%d", $2/1024 }' /proc/meminfo)
  available_mb=$(awk '/MemAvailable/ { printf "%d", $2/1024 }' /proc/meminfo)
  used_mb=$((total_mb - available_mb))

  printf "OS: Linux\n"
  printf "Total RAM: %s\n" "$(format_mb "$total_mb")"
  printf "Used RAM: %s\n" "$(format_mb "$used_mb")"
  printf "Available RAM: %s\n" "$(format_mb "$available_mb")"
}

print_macos_ram() {
  local total_bytes page_size pages_free pages_inactive available_bytes used_bytes
  local total_mb available_mb used_mb

  total_bytes=$(sysctl -n hw.memsize)
  page_size=$(vm_stat | awk '/page size of/ { gsub("\\.", "", $8); print $8 }')
  pages_free=$(vm_stat | awk '/Pages free/ { gsub("\\.", "", $3); print $3 }')
  pages_inactive=$(vm_stat | awk '/Pages inactive/ { gsub("\\.", "", $3); print $3 }')

  available_bytes=$(((pages_free + pages_inactive) * page_size))
  used_bytes=$((total_bytes - available_bytes))

  total_mb=$((total_bytes / 1024 / 1024))
  available_mb=$((available_bytes / 1024 / 1024))
  used_mb=$((used_bytes / 1024 / 1024))

  printf "OS: macOS\n"
  printf "Total RAM: %s\n" "$(format_mb "$total_mb")"
  printf "Used RAM: %s\n" "$(format_mb "$used_mb")"
  printf "Available RAM: %s\n" "$(format_mb "$available_mb")"
}

case "$(uname -s)" in
  Linux)
    print_linux_ram
    ;;
  Darwin)
    print_macos_ram
    ;;
  *)
    printf "Unsupported operating system: %s\n" "$(uname -s)" >&2
    exit 1
    ;;
esac
