# VirtualLive-2025-01-Garnet
[![IMAGE ALT TEXT HERE](https://github.com/user-attachments/assets/29771bf1-b733-4ddf-8433-114b60482e8a)](https://www.youtube.com/watch?v=NYrE7lXm0GY)
## はじめに
権利関係の3Dモデル、音声、モーションは一切gitで管理していないので、もし鑑賞される際は公式配布元より購入・ダウンロードをお願いします。

## Installation
1.
```
mkdir LiveApp
cd LiveApp
git clone https://github.com/HaruoOgawa/Garnet.git
cd Garnet
git checkout 0.2.0
cd ../
git clone https://github.com/HaruoOgawa/VirtualLive-2025-01-Garnet.git
git checkout release/sample-scene
```
2. https://aps.autodesk.com/developer/overview/fbx-sdk からWindows VS2022用のFBX SDKのインストーラーを取得しインストール
3. その後、Garnet\Garnet\Src\Library\FBXSDKに2020.3.7フォルダの中身をコピーします
 <img width="600" height="357" alt="image" src="https://github.com/user-attachments/assets/53ddaa21-9625-45db-8d18-883246a351df" />
 
4. ソリューション構成をDebugGLFWにしてF5デバッグ
