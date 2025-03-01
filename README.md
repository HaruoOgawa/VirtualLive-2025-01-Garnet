# VirtualLive-2025-01-Garnet
## はじめに
権利関係の3Dモデル、音声、モーションは一切gitで管理していないので、もし鑑賞される際は公式配布元より購入・ダウンロードをお願いします。
## 導入手順
1. [Garnet ver 0.20](https://github.com/HaruoOgawa/Garnet/releases/tag/0.20)をクローンもしくはダウンロード
2. このリポジトリをGarnetと同じディレクトリにクローンもしくはダウンロード
3. 任意のPMXを用意し、(クローンしたディレクトリ)/VirtualLive-2025-01-Garnet/Resources/Model/Performer/Performer.pmxとして配置(pmxとその親フォルダをPerformerにリネーム)
4. [デコレートのMV](https://www.youtube.com/watch?v=xIpIbc7IEWo)よりMMD配布モーションをダウンロードしResources/Motion/decorate.vmdとして配置
5. (任意) [デコレートのMV](https://www.youtube.com/watch?v=xIpIbc7IEWo)より曲を購入。ショート動画用に55.5秒から86.0秒の間でトリミング後、Resources/Sound/decorate_short.wavとして配置
6. ソリューション構成をReleaseGLFWでビルドする
7. ビルドしてできたx64/ReleseGLFWにResourcesフォルダをコピー
8. VirtualLive-2025-01-Garnet.exeを実行
