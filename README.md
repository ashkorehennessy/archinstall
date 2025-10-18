# 用法

建议提前用可视化工具分配好分区，如diskgenius、kde分区管理器，确保有EFI和根分区

进入archiso后，先确保连上网，dns没有问题，连接wifi使用iwctl，然后获取并运行安装脚本

```bash
bash -c "$(curl -fsSL i.ashkore.sbs)"
```

如果上面的短链接失效，改用

```bash
bash -c "$(curl -fsSL https://ashkorehennessy.oss-cn-shanghai.aliyuncs.com/arch-install.sh)"
```

跟着提示完成安装即可，其中需要输入三个路径，分别是根分区设备路径、EFI分区设备路径、引导启动设备路径，默认会安装kde fcitx5 v2rayn
