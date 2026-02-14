# NixOS 配置指南

## 目录

- [项目简介](#项目简介)
- [个性化配置](#个性化配置)
- [安装步骤](#安装步骤)
- [配置说明](#配置说明)
- [常见问题](#常见问题)

---

## 项目简介

这是一个 NixOS 配置文件仓库，包含完整的系统、桌面（Hyprland/KDE/Plasma/GNOME）和开发环境配置。

### 主要功能

- **模块化设计**：系统级和用户级配置分离
- **多种桌面环境**：支持 Hyprland、KDE Plasma、GNOME
- **主题系统**：通过 Stylix 支持多种主题切换
- **Home Manager**：管理用户级应用配置
- **自动化工具**：phoenix 脚本简化系统更新

### 目录结构

```
.
├── flake.nix                    # Flake 入口文件
├── install.org                  # 安装笔记（原版英文）
├── README.zh-CN.md              # 本中文文档
├── hosts/                       # 主机配置目录
│   ├── TEMPLATE/                # 新主机配置模板
│   ├── snowfire/                # 主游戏笔记本
│   ├── duskfall/                # 备用 ThinkPad
│   ├── stardust/                # 妻子笔记本
│   ├── zenith/                  # 工作笔记本
│   └── ori/                     # homelab 服务器
├── modules/
│   ├── system/                  # 系统级配置模块
│   │   ├── configuration.nix   # 核心系统配置
│   │   ├── phoenix/             # 自动化脚本
│   │   ├── stylix/              # 主题系统
│   │   ├── hyprland/            # Hyprland 配置
│   │   └── ...
│   ├── user/                    # 用户级配置模块
│   │   ├── userInfo/            # 用户信息定义
│   │   ├── git/                 # Git 配置
│   │   ├── hyprland/            # 用户 Hyprland 设置
│   │   └── ...
│   └── themes/                  # 主题模块（大量主题）
└── patches/                     # nixpkgs 补丁
```

---

## 个性化配置

在开始使用本配置之前，你需要修改以下设置以适应你的环境。

### 1. 必须修改的配置项

| 配置项 | 说明 | 所在文件 | 行号 |
|--------|------|----------|------|
| `USERNAME` | 系统用户名 | `hosts/TEMPLATE/configuration.nix` | 7, 8, 51 |
| `NAME` | 用户全名 | `hosts/TEMPLATE/configuration.nix` | 51, 52 |
| `EMAIL` | 用户邮箱 | `hosts/TEMPLATE/configuration.nix` | 52-54 |
| `dotfilesDir` | dotfiles 目录路径 | `hosts/TEMPLATE/configuration.nix` | 30 |

### 2. 系统级配置（建议修改）

| 配置项 | 说明 | 所在文件 | 行号 |
|--------|------|----------|------|
| `time.timeZone` | 系统时区 | `modules/system/configuration.nix` | 14 |
| `nix.nixPath` | Nix 搜索路径 | `modules/system/configuration.nix` | 35-37 |

### 3. SSH 密钥配置（仅服务器需要）

如果使用 `ori` 主机配置作为服务器模板，必须修改 SSH 密钥：

**文件**: `hosts/ori/configuration.nix` (第 40-42 行)

```nix
users.users.你的用户名.openssh.authorizedKeys.keys = [
  "ssh-rsa AAAAB3... 你的公钥内容"
];
```

**重要**：原配置包含作者的 SSH 公钥，部署服务器时务必替换或删除！

### 4. Secrets 配置（可选但推荐）

Secrets 仓库用于存储敏感配置（API 密钥、密码等），允许你公开主配置仓库而不泄露敏感信息。

**文件**: `flake.nix` (第 133-136 行)

```nix
secrets = {
  url = "git+file:///etc/nixos.secrets";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

#### 设置 Secrets 仓库

1. 克隆模板仓库：
   ```sh
   git clone https://gitlab.com/librephoenix/nixos-secrets-template.git /etc/nixos.secrets
   cd /etc/nixos.secrets
   ```

2. 按照模板仓库中的说明初始化

3. 在 secrets 仓库中创建对应主机的配置文件

**注意**：如果不想使用 secrets，删除 `flake.nix` 中所有对 `secrets` 的引用。

---

## 安装步骤

### 前提条件

- 已安装 NixOS 的系统
- 具有 sudo 权限的用户
- 稳定的网络连接（用于下载 nixpkgs）

### 第一步：克隆仓库

将仓库克隆到 `/etc/nixos` 目录：

```sh
sudo mv /etc/nixos /etc/nixos.bkp
git clone https://gitlab.com/librephoenix/nixos-config.git /etc/nixos
```

或者克隆到自定义目录：

```sh
git clone https://gitlab.com/librephoenix/nixos-config.git /你的/自定义/目录
```

### 第二步：配置新主机

1. 进入 hosts 目录并复制模板：

   ```sh
   cd /etc/nixos/hosts
   cp -r TEMPLATE 你的主机名
   ```

2. 编辑 `hosts/你的主机名/configuration.nix`：

   ```nix
   {
     systemSettings = {
       # 用户配置
       users = [ "你的用户名" ];           # 第 7 行
       adminUsers = [ "你的用户名" ];      # 第 8 行

       # dotfiles 目录（使用自定义目录时需要修改）
       dotfilesDir = "/etc/nixos";         # 第 30 行
     };

     users.users.你的用户名 = {
       description = "你的全名";           # 第 51 行
     };

     home-manager.users.你的用户名.userSettings = {
       name = "你的全名";                  # 第 52 行
       email = "你的邮箱@example.com";     # 第 52-54 行
     };
   }
   ```

3. 编辑 `hosts/你的主机名/home.nix`：

   根据需要启用/禁用各项功能：

   ```nix
   {
     userSettings = {
       # Shell 配置
       shell = {
         enable = true;
         apps.enable = true;
         extraApps.enable = true;
       };

       # 程序配置
       browser = "brave";      # 浏览器选择
       editor = "emacs";        # 编辑器选择
       git.enable = true;       # 启用 Git

       # 桌面环境
       hyprland.enable = true;  # Hyprland 桌面

       # 样式
       stylix.enable = true;    # 启用主题系统
     };
   }
   ```

### 第三步：配置硬件信息

复制或生成硬件配置：

```sh
sudo nixos-generate-config --show-hardware-config > /etc/nixos/hosts/你的主机名/hardware-configuration.nix
```

### 第四步：（可选）配置 Secrets

如前所述设置 secrets 仓库，或跳过此步。

### 第五步：应用配置

构建并切换到新配置：

```sh
sudo nixos-rebuild switch --flake /etc/nixos#你的主机名
```

使用自定义目录时：

```sh
sudo nixos-rebuild switch --flake /你的/自定义/目录#你的主机名
```

### 后续更新

后续重建可以使用 `phoenix` 脚本：

```sh
phoenix sync
```

---

## 配置说明

### 系统配置模块 (modules/system/)

| 模块 | 说明 |
|------|------|
| `configuration.nix` | 核心系统配置（时区、本地化、启动项等） |
| `phoenix/` | 自动化更新脚本 |
| `stylix/` | 主题系统配置 |
| `hyprland/` | Hyprland 系统级配置 |
| `kernel/` | 内核配置 |
| `nix/` | Nix 配置 |
| `bluetooth/` | 蓝牙配置 |
| `gaming/` | 游戏相关配置 |
| `security/` | 安全配置（防火墙、GPG、SSH 等） |

### 用户配置模块 (modules/user/)

| 模块 | 说明 |
|------|------|
| `userInfo/` | 用户信息选项定义 |
| `git/` | Git 配置 |
| `hyprland/` | Hyprland 用户配置 |
| `xdg/` | XDG 目录配置 |
| `stylix/` | Stylix 用户配置 |

### 主题模块 (modules/themes/)

支持多种主题，包括但不限于：

- catppuccin-mocha/frappe
- dracula
- nord
- gruvbox-dark/light
- solarized-dark/light
- tokyo-night
- tomorrow-night
- 以及更多...

在 `configuration.nix` 中修改：

```nix
stylix = {
  enable = true;
  theme = "你选择的主题名称";
};
```

### phoenix 脚本命令

| 命令 | 说明 |
|------|------|
| `phoenix sync` | 同步系统配置 |
| `phoenix update` | 更新所有 flake inputs |
| `phoenix update INPUT` | 更新指定 input |
| `phoenix build` | 构建所有主机配置 |
| `phoenix build 主机名` | 构建指定主机配置 |
| `phoenix pull` | 从上游拉取并合并更改 |
| `phoenix lock` | 锁定配置文件权限 |
| `phoenix unlock` | 解锁配置文件权限 |
| `phoenix gc` | 清理 nix store |
| `phoenix gc 15d` | 清理 15 天前的旧引用 |

---

## 常见问题

### Q: 安装到虚拟机后，登录后崩溃返回登录界面？

**A**: Hyprland 需要 3D acceleration。请在虚拟机设置中启用 3D 加速。

### Q: 提示找不到 `secrets` 输入？

**A**: 你需要：
1. 设置 `/etc/nixos.secrets` 目录（使用 secrets 模板仓库），或者
2. 删除 `flake.nix` 中所有对 `secrets` 的引用

### Q: 如何添加新的用户？

**A**: 在对应主机的 `configuration.nix` 中：

```nix
{
  systemSettings = {
    users = [ "用户1" "用户2" ];       # 添加用户名
    adminUsers = [ "用户1" ];         # 管理员用户
  };

  users.users.用户2 = {
    description = "用户2的描述";
  };

  home-manager.users.用户2.userSettings = {
    name = "用户2全名";
    email = "user2@example.com";
  };
}
```

### Q: 如何修改系统时区？

**A**: 在 `modules/system/configuration.nix` 中修改：

```nix
time.timeZone = "Asia/Shanghai";  # 例如 "Asia/Shanghai"
```

### Q: nixPath 是什么，需要修改吗？

**A**: `nixPath` 定义了 Nix 的搜索路径。如果使用自定义目录，可能需要修改：

```nix
nix.nixPath = [
  "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
  "nixos-config=$HOME/你的目录/system/configuration.nix"
  "/nix/var/nix/profiles/per-user/root/channels"
];
```

### Q: 原来的自动安装脚本去哪里了？

**A**: 旧的自动安装脚本已不再维护。未来可能会使用 [nixos-anywhere](https://github.com/nix-community/nixos-anywhere) 和 [disko](https://github.com/nix-community/disko) 重新实现。

### Q: 如何在现有系统上测试配置而不影响当前系统？

**A**: 可以在虚拟机中测试：
1. 创建新的虚拟机
2. 挂载 NixOS ISO
3. 按照上述步骤配置
4. 确保虚拟机启用 3D acceleration（如果使用 Hyprland）

---

## 其他说明

### 清理旧配置

如果需要回滚到原始安装：

```sh
sudo rm -rf /etc/nixos
sudo mv /etc/nixos.bkp /etc/nixos
```

### 硬件配置说明

`hardware-configuration.nix` 由 `nixos-generate-config` 生成，包含你的硬件特定配置（文件系统类型、挂载点、内核模块等）。每次安装新系统时都需要重新生成此文件。

### 更新 flake inputs

```sh
# 更新所有 inputs
phoenix update

# 更新指定 input
phoenix update nixpkgs
```

### 贡献

欢迎提交 Issue 和 Pull Request！

---

## 参考链接

- [主仓库 (GitLab)](https://gitlab.com/librephoenix/nixos-config)
- [镜像仓库 (GitHub)](https://github.com/librephoenix/nixos-config)
- [镜像仓库 (Codeberg)](https://codeberg.org/librephoenix/nixos-config)
- [Secrets 模板仓库](https://gitlab.com/librephoenix/nixos-secrets-template)
- [Stylix 主题系统](https://github.com/danth/stylix)
- [Home Manager](https://github.com/nix-community/home-manager)
