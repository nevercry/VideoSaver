var MyExtensionJavaScriptClass = function() {};

MyExtensionJavaScriptClass.prototype = {
run: function(arguments) {
    var originURL = document.URL ? document.URL : ""; //网站地址
    var videoInfo = { title: "unknow", url:"", poster:"", duration:"", type:"video/mp4", source:originURL }; // 视频信息
    
    if (document.title) {
        videoInfo.title = document.title;
    }
    
    // 验证VideoInfo
    function checkVideoInfo() {
        if (videoInfo.url.includes("m3u8")) {
            videoInfo.type = "m3u8";
        }
    }
    
    // 转换时间
    function seconds2time (seconds) {
        seconds = Math.ceil(seconds);
        var hours   = Math.floor(seconds / 3600);
        var minutes = Math.floor((seconds - (hours * 3600)) / 60);
        var seconds = seconds - (hours * 3600) - (minutes * 60);
        var time = "";
        
        if (hours != 0) {
            time = hours+":";
        }
        if (minutes != 0 || time !== "") {
            minutes = (minutes < 10 && time !== "") ? "0"+minutes : String(minutes);
            time += minutes+":";
        }
        if (time === "") {
            time = (seconds < 10) ? "0:0"+seconds : "0:"+String(seconds);
        }
        else {
            time += (seconds < 10) ? "0"+seconds : String(seconds);
        }
        return time;
    }
    
    // 解析Youtube
    function youtubeParse() {
        // youtube
        var elem = document.getElementsByTagName("video")[0];
        var vIndex = document.URL.search('v=');
        var vId = document.URL.slice(vIndex+2);
        // 解析URL 获得时长
        var searchs = elem.src.split('?')[1].split('&');
        for (var pairs of searchs) {
            if (pairs.includes('dur=')) {
                var dur = pairs.split('=')[1];
                videoInfo.duration = seconds2time(parseInt(dur,10));
                break;
            }
        }
        
        videoInfo.title = elem.title;
        videoInfo.url = elem.src;
        videoInfo.poster = "https://i.ytimg.com/vi/" + vId + "/hqdefault.jpg";
    }
    
    // 解析youku
    function youkuParse() {
        var elem = document.getElementsByTagName("video")[0]; // 在iPad上会给出flv类型的视频
        if (elem.src.includes('flv')) {
            elem.src = elem.src.replace('flv','mp4');
        }
        
        var detail = document.getElementsByClassName('detail-h')[0];
        
        if (detail) {
            videoInfo.title = detail.firstChild.textContent.trim();
        }
        videoInfo.url = elem.src;
        var duration = document.getElementsByClassName('x-video-state')[0].textContent;
        if (duration) {
            videoInfo.duration = duration;
        } else {
            videoInfo.duration = document.getElementsByClassName('x-time-duration')[0].textContent; // v.youku 可能只显示在这里
        }
        videoInfo.poster = document.getElementsByClassName('x-video-poster')[0].firstChild.src;
    }
    
    // 解析gfycat
    function gfycatParse() {
        var sources = document.getElementsByTagName("source");
        var elem;
        for (var i = 0; i < sources.length; i++) {
            var source = sources[i];
            if (source.type.includes("video/mp4")) {
                elem = source;
                break;
            }
        }
        var vUrl = new URL(elem.src);
        videoInfo.title = vUrl.pathname.slice(1,-4);
        videoInfo.url = elem.src;
        videoInfo.poster = elem.parentNode.poster;
        
        var duration_seconds = elem.parentNode.duration;
        if (duration_seconds) {
            videoInfo.duration = seconds2time(duration_seconds);
        }
    }
    
    // 解析bilibili
    function bilibiliParse() {
        // iPhone
        var share_pic = document.getElementById('share_pic');
        if (share_pic) {
            videoInfo.title = share_pic.alt;
            videoInfo.poster = share_pic.src;
        } else {
            // iPad
            videoInfo.title = document.getElementsByClassName('v-title')[0].textContent;
            videoInfo.poster = document.getElementsByClassName('cover_image')[0].src;
        }
        videoInfo.url = document.getElementsByTagName('source')[0].src;
        videoInfo.duration = document.getElementsByClassName('time-total-text')[0].textContent;
    }
    
    // 解析twitter
    function twitterParse() {
        var sources = document.getElementsByTagName("source");
        var initdata = document.getElementById('init-data');
        var elem;
        if (initdata) {
            // 非登录
            var jsonData = JSON.parse(initdata.innerHTML);
            elem = sources[0];
            var textParts_first = jsonData.state.tweet.text.textParts[0];
            if (textParts_first) {
                videoInfo.title = textParts_first.text;
            } else {
                videoInfo.title = jsonData.state.tweet.text.textString;
            }
            
            if (jsonData.state.tweet.inlineMedia.mediaDetails.duration) {
                videoInfo.duration = jsonData.state.tweet.inlineMedia.mediaDetails.duration;
            } else {
                videoInfo.duration = "0:06"
            }
            
        } else {
            // 已登录
            for (var i = 0; i < sources.length; i++) {
                var source = sources[i];
                if (source.type.includes("video/mp4")) {
                    elem = source;
                    break;
                }
            }
            
            if (elem.src.includes('.vine.')) {
                // vine
                videoInfo.duration = "0:06";
            } else {
                var duration_seconds = document.getElementsByTagName('video')[0].duration;
                videoInfo.duration = seconds2time(duration_seconds);
            }
            
            var vUrl = new URL(elem.src);
            var vPath = vUrl.pathname.slice(1,-4);
            var vComps = vPath.split('/');
            var lastCom = vComps.pop();
            videoInfo.title = lastCom;
        }
        videoInfo.poster = document.getElementsByTagName('video')[0].poster;
        videoInfo.url = elem.src;
    }
    
    // 解析twimg
    function twimgParse() {
        var vmap = document.head.querySelector("meta[name='twitter:amplify:vmap']").content;
        var durationStr = document.head.querySelector("meta[name='twitter:amplify:content_duration_seconds']").content;
        var elem = document.getElementById('iframe').contentWindow.document.getElementsByTagName('video')[0];
        
        videoInfo.title = document.title;
        videoInfo.url = vmap;
        videoInfo.duration = seconds2time(parseInt(durationStr,10));
        videoInfo.poster = elem.poster;
        videoInfo.type = "xml";
    }
    
    // 腾讯视频
    function qqParse() {
        var tvp_title = document.getElementsByClassName('tvp_title')[0];
        if (tvp_title) {
            videoInfo.title = tvp_title.textContent;
        } else {
            videoInfo.title = document.getElementsByClassName('video_title')[0].textContent;
        }
        videoInfo.url = document.getElementsByTagName('video')[0].src;
        
        var tvp_time_panel_total = document.getElementsByClassName('tvp_time_panel_total')[0];
        if (tvp_time_panel_total) {
            videoInfo.duration = tvp_time_panel_total.textContent;
        } else {
            videoInfo.duration = document.getElementsByClassName('txp_time_duration')[0].textContent;
        }
        
        
        var meta = document.querySelector('meta[itemprop="image"]');
        if (meta) {
            videoInfo.poster = meta.content;
        } else {
            videoInfo.poster = document.getElementById('share_qq_img').children[0].src;
        }
        
    }
    
    // 秒拍
    function miaopaiParse() {
        var videoElem = document.getElementById('video');
        videoInfo.title =  document.querySelector('meta[name="description"]').content;
        videoInfo.url = videoElem.src;
        videoInfo.poster = document.getElementsByClassName('video_img')[0].dataset.url;
        
        var duration_seconds = videoElem.duration;
        if (duration_seconds) {
            videoInfo.duration = seconds2time(duration_seconds);
        }
    }
    
    // weibo
    function weiboParse() {
        otherParse();
        var description = document.querySelector('meta[name="description"]');
        if (description) {
            videoInfo.title = description.content;
        } else {
            videoInfo.title = document.getElementsByClassName('weibo-detail')[0].getElementsByClassName('default-content')[0].textContent
        }
        
        var poster = document.getElementsByClassName('poster')[0];
        if (poster) {
            videoInfo.poster = poster.src;
        }
    }
    
    function otherParse() {
        // 其他网站
        var sources = document.getElementsByTagName("source");
        var elem;
        for (var i = 0; i < sources.length; i++) {
            var source = sources[i];
            if (source.type.includes("video/mp4") || source.src.endsWith(".mp4")) {
                elem = source;
                break;
            }
        }
        
        var videos = document.getElementsByTagName('video');
        if (videos.length > 0) {
            var video = videos[0];
            var poster = video.poster;
            var duration_seconds = video.duration;
            if (poster) {
                videoInfo.poster = poster;
            }
            
            if (duration_seconds) {
                videoInfo.duration = seconds2time(duration_seconds)
            }
            
            if (elem) {
                videoInfo.url = elem.src;
            } else {
                for (var i = 0; i < videos.length; i++) {
                    var vd = videos[i];
                    if (vd.src) {
                        if (vd.src.includes('mp4')) {
                            videoInfo.url = vd.src;
                            break;
                        }
                    }
                }
            }
            
            if (videoInfo.url) {
                var vUrl = new URL(videoInfo.url);
                var urlComponents = vUrl.pathname.split('/');
                var lastComponent = urlComponents.pop();
                videoInfo.title = lastComponent.slice(1,-4);
            }
        }
    }
    
    if (originURL.includes("youtube.com")) {
        youtubeParse();
    } else if (originURL.includes("youku.com")) {
        youkuParse();
    } else if (originURL.includes("gfycat.com")) {
        gfycatParse();
    } else if (originURL.includes('bilibili.com')) {
        bilibiliParse();
    } else if (originURL.includes('twitter.com')) {
        twitterParse();
    } else if (originURL.includes('amp.twimg.com')) {
        twimgParse();
    } else if (originURL.includes('v.qq.com')) {
        qqParse();
    } else if (originURL.includes('miaopai.com')) {
        miaopaiParse();
    } else if (originURL.includes('.weibo.')) {
        weiboParse();
    } else {
        otherParse();
    }
    
    // 再检查一遍VideInfo
    checkVideoInfo();
    
    arguments.completionFunction({"videoInfo":videoInfo});
},
    
    // Note that the finalize function is only available in iOS.
finalize: function(arguments) {
    // arguments contains the value the extension provides in [NSExtensionContext completeRequestReturningItems:completion:].
    // In this example, the extension provides a color as a returning item.
    document.body.style.backgroundColor = arguments["bgColor"];
}
};

// The JavaScript file must contain a global object named "ExtensionPreprocessingJS".
var ExtensionPreprocessingJS = new MyExtensionJavaScriptClass;
