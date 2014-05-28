## 概述
**MuPlayer** 是百度 [@音乐前端](http://weibo.com/musicfe) 团队开发维护的浏览端音频播放内核，它基于 HTML5 Audio 及 Flash 音频技术，实现了*多端通用（PC & WebApp）、浏览器兼容（ie6+、firefox、chrome、safari etc）及可扩展的多音频格式解码插件*的音频文件播放功能，并在百度音乐多个线上产品线中应用，具备相当的灵活性和稳定性。


## 安装

你可以使用 [bower](https://github.com/bower/bower) 安装

    bower install muplayer

或者到发布页面下载压缩文档：[Releases](https://github.com/Baidu-Music-FE/muplayer/releases)

具体使用方法请参见档部分。

## 文档

### 参见：[MuPlayer API](http://labs.music.baidu.com/demo/muplayer/doc/api.html)

### 示例：[Demo](http://labs.music.baidu.com/demo/muplayer/doc/demo.html)


## 为项目贡献代码

 1. 签出项目

        git clone https://github.com/Baidu-Music-FE/muplayer.git
        cd muplayer

 2. 如果你没有全局安装 [coffee](http://coffeescript.org/)，请先安装它

        npm install -g coffee-script

    安装依赖

        npm install

    这个步骤会提示你是否安装 Flex SDK，如果选择 `no`， 项目会利用现有的编译好的 `swf` 文件。如果你希望更改 action script 源码并编译，请选择 `yes`，注意这个 SDK 可能会需要下载 400MB 的依赖。

 3. 编译

        cake build

    编译好的文件会保存到 `dist` 文件夹。


## 修订文档

 1. 编译文档

        cake doc

 2. 预览文档需要启动本地服务器

        cake server

    指定端口号

        cake -p 8080 server


## 许可
**MuPlayer** 实行 MIT 许可协议.
版权 (c) 2014 Baidu Music

被授权人有权利使用、复制、修改、合并、出版发行、散布、再授权及贩售软件及软件的副本。
被授权人可根据程序的需要修改授权条款为适当的内容。

在软件和软件的所有副本中都必须包含版权声明和许可声明。

此授权条款并非属 copyleft 的自由软件授权条款，允许在自由/开放源码软件或非自由软件（proprietary software）所使用。
MIT的内容可依照程序著作权者的需求更改内容。此亦为MIT与BSD（The BSD license, 3-clause BSD license）本质上不同处。
MIT条款可与其他授权条款并存。另外，MIT条款也是自由软件基金会（FSF）所认可的自由软件授权条款，与 GPL 兼容。
