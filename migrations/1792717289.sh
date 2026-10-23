echo "Unhide SSPM on the Lenovo Pro 9 15N1X11 so the internal keyboard powers on"

# Lenovo firmware hides \_SB.SSPM when Linux claims Windows 2022, which leaves
# the I2C keyboard (LENC0001) unpowered. New installs get this from
# install/hardware/n1x.sh. Dell and ASUS N1x firmware do not need it.
omarchy-hw-aarch64-n1x || exit 0
omarchy-hw-match "15N1X11" || omarchy-hw-match "83SS" || exit 0

limine_conf_dir="${OMARCHY_LIMINE_ENTRY_TOOL_DIR:-/etc/limine-entry-tool.d}"
dropin="$limine_conf_dir/00-omarchy-n1x-lenovo-osi.conf"
boot_order="$limine_conf_dir/zz-omarchy-n1x-boot-order.conf"
rebuild_marker="${OMARCHY_LIMINE_REBUILD_MARKER:-/var/lib/omarchy/migrations/1792717289}"

sudo install -Dm644 /dev/stdin "$dropin" <<'EOF'
# Lenovo N1x: firmware hides SSPM from an OS that claims Windows 2022, which
# leaves the I2C keyboard unpowered. Quotes keep Windows 2022 one parameter.
KERNEL_CMDLINE[default]+=" acpi_osi=\"!Windows 2022\""
EOF

if [[ -f $boot_order ]] && ! grep -Fq 'acpi_osi=\"!Windows 2022\"' "$boot_order"; then
  printf '%s\n' 'KERNEL_CMDLINE[fallback]+=" acpi_osi=\"!Windows 2022\""' | sudo tee -a "$boot_order" >/dev/null
fi

# Machine-wide rebuild. Another user's run must not repeat it; a missing
# marker still retries an interrupted rebuild.
[[ ! -e $rebuild_marker ]] || exit 0
sudo limine-mkinitcpio
sudo install -Dm644 /dev/null "$rebuild_marker"
