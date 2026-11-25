<p align="center">
  <img src="https://raw.githubusercontent.com/Dronecode/UX-Design/35d8148a8a0559cd4bcf50bfa2c94614983cce91/QGC/Branding/Deliverables/QGC_RGB_Logo_Horizontal_Positive_PREFERRED/QGC_RGB_Logo_Horizontal_Positive_PREFERRED.svg" alt="QGroundControl Logo" width="500">
</p>

<p align="center">
  <a href="https://github.com/mavlink/QGroundControl/releases"><img src="https://img.shields.io/github/v/release/mavlink/QGroundControl" alt="Latest Release"></a>
  <a href="https://github.com/mavlink/qgroundcontrol/blob/master/.github/COPYING.md"><img src="https://img.shields.io/github/license/mavlink/QGroundControl" alt="License"></a>
  <a href="https://github.com/mavlink/QGroundControl/actions/workflows/linux.yml"><img src="https://github.com/mavlink/QGroundControl/actions/workflows/linux.yml/badge.svg" alt="Linux Build"></a>
  <a href="https://securityscorecards.dev/viewer/?uri=github.com/mavlink/qgroundcontrol"><img src="https://img.shields.io/ossf-scorecard/github.com/mavlink/qgroundcontrol?label=openssf%20scorecard" alt="OpenSSF Scorecard"></a>
  <a href="https://crowdin.com/project/qgroundcontrol"><img src="https://badges.crowdin.net/qgroundcontrol/localized.svg" alt="Crowdin"></a>
  <a href="https://discord.com/channels/1022170275984457759/1022185820683255908"><img src="https://img.shields.io/discord/1022170275984457759?logo=discord&logoColor=white&label=Discord" alt="Dronecode Discord"></a>
  <a href="https://doi.org/10.5281/zenodo.595404"><img src="https://zenodo.org/badge/DOI/10.5281/zenodo.595404.svg" alt="DOI"></a>
</p>

**QGroundControl** (QGC) is a Ground Control Station (GCS) for UAVs, providing full flight control
and mission planning for any *MAVLink-enabled* drone, including *PX4* and *ArduPilot* platforms.

## Features

- **Mission planning** — plan, edit, and fly autonomous waypoint, survey, and structure-scan missions.
- **Live Fly View** — real-time flight display with map, instruments, and full vehicle telemetry.
- **Vehicle setup** — guided wizards for sensor calibration, radio, flight modes, and power.
- **Parameter tuning** — inspect and edit every vehicle parameter through the Fact System.
- **Video streaming** — GStreamer-based UDP RTP / RTSP video with recording in the Flight Display.
- **Multi-vehicle** — connect to and monitor multiple vehicles simultaneously.
- **MAVLink tooling** — built-in MAVLink Inspector, console, and log download/analysis.
- **Cross-platform** — Windows, macOS, Linux, Android, and iOS from a single codebase.

## Download

点击下方按钮直接下载简体中文预览版。本版修复了 IMU、光流和测距数据显示。更新说明和校验文件见[发布页面](https://github.com/yuxuan20230525/qgroundcontrol/releases/tag/v5.2.0-zh.3)。

<p align="center">
  <a href="https://github.com/yuxuan20230525/qgroundcontrol/releases/download/v5.2.0-zh.3/QGroundControl-zh-CN-Windows-x64.exe"><img src="https://img.shields.io/badge/Windows-%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87%E7%89%88-0078D6?logo=windows&amp;logoColor=white" alt="下载 Windows x64 简体中文版"></a>
  <a href="https://github.com/yuxuan20230525/qgroundcontrol/releases/download/v5.2.0-zh.3/QGroundControl-zh-CN-Linux-x86_64.AppImage"><img src="https://img.shields.io/badge/Linux-%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87%E7%89%88-FCC624?logo=linux&amp;logoColor=black" alt="下载 Linux x86_64 简体中文版"></a>
</p>

在 Linux 上，下载 AppImage 后为它添加执行权限，再启动应用。

```sh
chmod +x QGroundControl-zh-CN-Linux-x86_64.AppImage
./QGroundControl-zh-CN-Linux-x86_64.AppImage
```

如果系统提示缺少 FUSE，可以加上 `--appimage-extract-and-run` 参数启动。

上游官方版本见 [QGroundControl Releases](https://github.com/mavlink/QGroundControl/releases/latest)。

<p align="center">
  <a href="https://github.com/mavlink/QGroundControl/releases/latest/download/QGroundControl.dmg"><img src="https://img.shields.io/badge/macOS-000000?logo=apple&logoColor=white" alt="macOS"></a>
  <a href="https://github.com/mavlink/QGroundControl/releases/latest/download/QGroundControl.apk"><img src="https://img.shields.io/badge/Android-3DDC84?logo=android&logoColor=white" alt="Android"></a>
</p>

## Links

- [Official Website](https://qgroundcontrol.com)
- [User Manual](https://docs.qgroundcontrol.com/master/en/qgc-user-guide/)
- [Developer Guide](https://docs.qgroundcontrol.com/master/en/qgc-dev-guide/) / [Build Instructions](https://docs.qgroundcontrol.com/master/en/qgc-dev-guide/getting_started/)
- [Discussion & Support](https://docs.qgroundcontrol.com/master/en/qgc-user-guide/support/support.html)
- [Dronecode Discord](https://discord.com/channels/1022170275984457759/1022185820683255908)
- [Security Policy](.github/SECURITY.md)
- [Code of Conduct](.github/CODE_OF_CONDUCT.md)
- [License](https://github.com/mavlink/qgroundcontrol/blob/master/.github/COPYING.md)

## Contributing

QGC is open source and welcomes contributions. See [AGENTS.md](AGENTS.md) for build/test/lint
commands and coding conventions, and [.github/CONTRIBUTING.md](.github/CONTRIBUTING.md) for
architecture patterns and the contribution workflow.

QGC's interface is translated by the community — help translate it into your language on
[Crowdin](https://crowdin.com/project/qgroundcontrol).

## Star History

[![Star History Chart](https://star-history.dera.page/svg?repos=mavlink/qgroundcontrol&type=date&legend=top-left)](https://star-history.dera.page/#mavlink/qgroundcontrol&type=date&legend=top-left)
