#!/usr/bin/env bash
#
# NixOS 磁盘分区挂载脚本
#
# 特性:
#   - EFI: 512MB
#   - Swap: 8GB (swapfile)
#   - Root: btrfs + zstd:1 透明压缩
#

set -euo pipefail

DEVICE="/dev/nvme0n1"
EFI_SIZE="512MiB"
SWAP_SIZE="8G"

log_info() { echo "[INFO] $1"; }
log_warn() { echo "[WARN] $1"; }
log_error() { echo "[ERROR] $1"; }

if [[ $EUID -ne 0 ]]; then
    log_error "需要 root 权限"
    exit 1
fi

log_info "设备: $DEVICE"
log_warn "此操作将清除 $DEVICE 上的所有数据!"
# read -p "确认继续? (输入 yes): " confirm
# [[ "$confirm" != "yes" ]] && exit 0

# 1. 分区
log_info "创建分区..."
sgdisk --zap-all "$DEVICE" 2>/dev/null || true
parted "$DEVICE" -- mklabel gpt

parted "$DEVICE" -- mkpart ESP 1MiB ${EFI_SIZE}
parted "$DEVICE" -- set 1 esp on

parted "$DEVICE" -- mkpart primary ${EFI_SIZE} 100%

# 2. 格式化
EFI_PART="${DEVICE}p1"
ROOT_PART="${DEVICE}p2"

log_info "格式化..."
mkfs.fat -F 32 "$EFI_PART"
mkfs.btrfs -f "$ROOT_PART"

# 3. 创建 btrfs 子卷并挂载
log_info "创建子卷并挂载..."
mount "$ROOT_PART" /mnt

btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@persist
btrfs subvolume create /mnt/@swap

umount /mnt

mount -o compress=zstd:1,subvol=@ "$ROOT_PART" /mnt
mkdir -p /mnt/{boot,home,nix,persist,swap}
mount -o compress=zstd:1,subvol=@home "$ROOT_PART" /mnt/home
mount -o compress=zstd:1,subvol=@nix "$ROOT_PART" /mnt/nix
mount -o compress=zstd:1,subvol=@persist "$ROOT_PART" /mnt/persist
mount -o subvol=@swap "$ROOT_PART" /mnt/swap
mount "$EFI_PART" /mnt/boot

# 4. 创建 swapfile
log_info "创建 swapfile (${SWAP_SIZE})..."
btrfs filesystem mkswapfile --size ${SWAP_SIZE} /mnt/swap/swapfile
lsattr /mnt/swap
swapon /mnt/swap/swapfile

log_info "完成!"
lsblk "$DEVICE"
echo ""
df -h /mnt /mnt/boot
echo ""
swapon --show
