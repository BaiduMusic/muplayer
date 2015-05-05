## 概述
**MuPlayer** 是百度 [@音乐前端](http://weibo.com/musicfe) 团队开发维护的浏览端音频播放内核，它基于 HTML5 Audio 及 Flash 音频技术，实现了*多端通用（PC & WebApp）、浏览器兼容（ie6+、firefox、chrome、safari etc）及可扩展的多音频格式解码插件*的音频文件播放功能，并在百度音乐多个线上产品线中应用，具备相当的灵活性和稳定性。


## 安装
你可以使用 [bower](https://github.com/bower/bower) 安装
```
bower install muplayer
```

或者到发布页面下载压缩文档：[Releases](https://github.com/Baidu-Music-FE/muplayer/releases)

具体使用方法请参见文档部分。


## 文档
### 参见：[MuPlayer API](http://labs.music.baidu.com/demo/muplayer/doc/api.html)
### 示例：[Demo](http://labs.music.baidu.com/demo/muplayer/doc/demo.html)
### [常用事件说明](https://github.com/Baidu-Music-FE/muplayer/wiki/%E5%B8%B8%E7%94%A8%E4%BA%8B%E4%BB%B6%E8%AF%B4%E6%98%8E)


## 为项目贡献代码

 0. 签出项目
 ```
 git clone https://github.com/Baidu-Music-FE/muplayer.git
cd muplayer
 ```
 0. 安装依赖
 ```
 npm install
 ```
 这个步骤会提示你是否安装 Flex SDK，如果选择 `no`， 项目会利用现有的编译好的 `swf` 文件。如果你希望更改 action script 源码并编译，请选择 `yes`，注意这个 SDK 可能会需要下载 400MB 的依赖。如果想自动选择默认项安装（安静模式），请运行 `quiet=true npm install`

 0. 编译
 ```
 npm run no -- build
 ```
 编译好的文件会保存到 `dist` 文件夹。如果你全局安装了 [nokit](https://github.com/ysmood/nokit)，则可以直接运行 `no build`。


## 修订文档

 1. 编译文档
  ```
  npm run no -- doc
  ```

 2. 预览文档需要启动本地服务器，启动后访问 http://127.0.0.1:8077
  ```
  npm run no -- server
  ```
  指定端口号
  ```
  npm run no -- server -p 8080
  ```

## 使用案例
`MuPlayer`本就源自百度音乐前端团队在产品开发上的积累，被用于多条在线产品及音乐服务上，如[百度音乐盒](http://play.baidu.com/)，[百度随心听](http://fm.baidu.com/)，[百度音乐人](http://y.baidu.com)，[百度乐播](http://lebo.baidu.com)，及WebApp，是音乐前端的核心基础库之一。下面继续列举一些我们已知的第三方使用案例，以供参考：

 1. 百度个人中心的音乐随心听模块：http://i.baidu.com/#ibx-mod-music
 2. [@mozillazg](https://github.com/mozillazg) 实现的音乐FM：https://github.com/mozillazg/lark
 3. [@alankell](https://github.com/alankell) 的个人博客背景音播放：http://alankell.com/

## 许可
    MuPlayer 实行 BSD 许可协议。
    版权 (c) 2014 Baidu Music。

    这份授权条款，在使用者符合以下三条件的情形下，授予使用者使用及再散播本
    软件包装原始码及二进位可执行形式的权利，无论此包装是否经改作皆然：

    * 对于本软件源代码的再散播，必须保留上述的版权宣告、此三条件表列，以
      及下述的免责声明。
    * 对于本套件二进位可执行形式的再散播，必须连带以文件以及／或者其他附
      于散播包装中的媒介方式，重制上述之版权宣告、此三条件表列，以及下述
      的免责声明。
    * 未获事前取得书面许可，不得使用柏克莱加州大学或本软件贡献者之名称，
      来为本软件之衍生物做任何表示支持、认可或推广、促销之行为。

    免责声明：本软件是由加州大学董事会及本软件之贡献者以现状（"as is"）提供，
    本软件包装不负任何明示或默示之担保责任，包括但不限于就适售性以及特定目
    的的适用性为默示性担保。加州大学董事会及本软件之贡献者，无论任何条件、
    无论成因或任何责任主义、无论此责任为因合约关系、无过失责任主义或因非违
    约之侵权（包括过失或其他原因等）而起，对于任何因使用本软件包装所产生的
    任何直接性、间接性、偶发性、特殊性、惩罚性或任何结果的损害（包括但不限
    于替代商品或劳务之购用、使用损失、资料损失、利益损失、业务中断等等），
    不负任何责任，即在该种使用已获事前告知可能会造成此类损害的情形下亦然。
