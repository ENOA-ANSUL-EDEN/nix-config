# 覆盖 nixpkgs 默认的 Rime 数据，使用自定义方案数据。
# 参考： https://github.com/NixOS/nixpkgs/blob/e4246ae1e7f78b7087dce9c9da10d28d3725025f/pkgs/tools/inputmethods/fcitx5/fcitx5-rime.nix
_: (self: super: {
  fcitx5-rime = super.fcitx5-rime.override {
    rimeDataPkgs = [
      # nixpkgs 默认的 `rime-data` 包含 `rime-prelude` 等基础配置，
      # 部分 Rime 方案可能依赖其中的文件。
      #
      # 在 nixpkgs commit 4b2b576b0efd28e9f8535119760cbd8dc9bac5bd 之前，
      # 缺少 `default.yaml` 甚至可能导致 fcitx5-rime 无法正常工作。
      #
      # 如果自定义方案依赖这些基础配置，可以同时加入
      # `super.rime-data` 和自定义数据；否则可以仅使用自定义数据。
      #
      # super.rime-data

      self.rime-data-custom
    ];
  };

  # 导出自定义 Rime 数据，供不同平台和 Rime 前端复用。
  # 例如 fcitx5-rime 和 macOS Squirrel。
  rime-data-custom = ./rime-data-custom;
})