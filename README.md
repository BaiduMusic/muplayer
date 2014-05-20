## 概述
**MuPlayer** 是百度音乐FE Team开发维护的浏览端音频播放内核，它基于HTML5 Audio及Flash音频技术，实现了*多端通用（PC & WebApp）、浏览器兼容（ie6+、firefox、chrome、safari etc）及可扩展的多音频格式解码插件*的音频文件播放功能，并在百度音乐多个线上产品线中应用，具备相当的灵活性和稳定性。


## 源码目录
```text
muplayer/
  +src/             (源码)
    +demo.html      (一个完整的播放器demo示例)
  +lib/             (第三方库、工具及grunt编译等)
    +Gruntfile.js   (grunt配置)
    +bower.json     (demo运行需要安装的静态文件声明)
    +package.json   (grunt和bower等npm包的安装依赖声明)
  +doc/             (本地Demo及API文档)
  +test/            (qunit test)
  +dist/            (grunt编译后生成的最终引用文件)
```


## 签出源码并运行本地Demo
签出代码并安装必要依赖需执行：

```shell
curl https://raw.githubusercontent.com/Baidu-Music-FE/muplayer/lib/install.sh | sh
```

之后进入lib/目录并运行 `grunt server [-p your port]`，可在 `localhost` 开启一个webserver。其中，-p为可选参数，可以指定server开启的端口（默认是7777）：

```shell
cd muplayer/lib
grunt server
```

之后，便可以访问并查看 [本地文档及Demo](http://localhost:7777/) 了。


## API详解
参见：[MuPlayer API](http://labs.music.baidu.com/demo/muplayer/doc/api.html)

## 事件说明
在播放内核的实现中，事件的派发非常重要，这是解耦内核与UI交互的最佳方式 (客户端可自行监听需要的事件并做出相应的UI响应)。除上述部分API方法会派发诸如player:play，player:add等操作相关的事件外，下面还讲对播放状态相关的事件做一说明。
所有事件常量见 `cfg.coffee` 中的声明。默认对外派发的事件遵循精简且与HTML5 Auido规范统一的原则，player实例对外派发的事件点有三个：
1. `EVENTS.STATECHANGE` 时，派发具体的change后的新状态。因此可以监听cfg.coffee中定义的所有STATES常量对应的状态。
2. `EVENTS.POSITIONCHANGE` 时，会派发timeupdate事件。
3. `EVENTS.PROGRESS` 时，会派发progress事件。
若以上均无法满足需求(在我们内部的产品中，还未曾遇到)，可以进一步监听player.engine的相应事件。


## License
**MuPlayer** is released under the MIT License.
Copyright (c) 2014 Baidu Music

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
