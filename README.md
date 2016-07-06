# VideoSaver
在iPhone上看到一段有趣的视频，想要把它下载到照片里收藏，是件麻烦的事。iOS不支持文件下载，而视频网站为了保护自己的内容，只在自己的App里提供缓存功能。所以我开发了 **VideoSaver**，一个简单易用的Safari视频下载插件。

它的原理很简单：当Safari载入网页后，插件可以运行自定义的JS，这样我们就可以获得网页中的视频地址，轻松下载到想要保存的地方。

**VideoSaver** 已在Github开源，你可以通过Mac下载，用Xcode编译到你自己的iPhone、iPad上。`注：由于 VideoSaver在数据传输上利用了AppGroup技术，免费的开发者账号将无法使用` 请在编译时创建并替换为你的App Group ID。

###Extension###
**VideoSaver**的主要部件是它的**extension**。当安装到iPhone 、iPad后，请先在Safari的插件管理中打开插件。

<img src='https://github.com/nevercry/VideoSaver/blob/gh-pages/images/videoSaverExtension.gif' width='480px'>

在项目的 `VideoExtension` 目录下，有个名为 `MyJSFile.js` 的文件，插件通过它来操作当前网页的DOM。你可以在此对特定的视频网站做自定义解析，可以利用Mac上的 **Safari Web Inspector** 查看iPhone上的网页源码进行调试。具体方式和工具可以参考：[WWDC 2014 Session 512](https://developer.apple.com/videos/play/wwdc2014/512/) 。

###如何使用###
用Safari打开视频网页，确认视频能够播放，点击Safari 分享图标，使用插件下载。

<img src='https://github.com/nevercry/VideoSaver/blob/gh-pages/images/videoSaverHowToUse_1.gif' width='640px'>

你可以选择直接下载视频，也可以点击右上角的 `存储` ，将视频链接保存到应用内以便稍后下载。

<img src='https://github.com/nevercry/VideoSaver/blob/gh-pages/images/videoSaverHowToUser_2.gif' width='640px'>

当你在应用内下载收藏的视频，可以切换到其他应用，下载任务将在后台继续进行。**VideoSaver** 支持视频循环播放，iPad版支持画中画，多任务。

<img src='https://github.com/nevercry/VideoSaver/blob/gh-pages/images/videoSaverPiP.gif' width='750px'>

原生支持的视频网站有`Youtube`、 `Gfycat`、`Imgur`、`哔哩哔哩`、`秒拍`等等，大部分提供`mp4`视频的网页都可以解析到视频地址。 

###VideoMarks###
由于版权问题 **VideoSaver** 无法上架App Store，我去掉了 **VideoSaver** 的下载功能，只提供视频网址解析与收藏的服务，改名为 **VideoMarks**（**影签**）现已上架。你可以搭配强大的Workflow，完成下载的需求。当然 **VideoMarks** 也可以作为你的视频书签，记录你感兴趣的视频网址。

<a href='https://itunes.apple.com/cn/app/videomarks/id1123317863?l=en&mt=8'><img src="https://devimages.apple.com.edgekey.net/app-store/marketing/guidelines/images/badge-download-on-the-app-store.svg" alt=""></a>
