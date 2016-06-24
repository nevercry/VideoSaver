var MyExtensionJavaScriptClass = function() {};

MyExtensionJavaScriptClass.prototype = {
run: function(arguments) {
    var url; // 网站地址
    var videoURL; // 视频地址
    var videoType; // 视频类型
    url = document.URL;
    if (document.URL) {
        url = document.URL;
    } else {
        url = "";
    }
    
    
    videoType = "video/mp4";

    
    var elem; // 包含视频的element
    if (url.startsWith("https://m.youtube.com")) {
        // youtube
        var elems = document.getElementsByTagName("video");
        elem = elems[0];
    } else {
        // 其他网站
        var elements = document.getElementsByTagName("source");
        for (var i=0;i<elements.length;i++) {
            var el = elements[i];
            if (el.type === "video/mp4" || el.src.endsWith(".mp4") || el.src.includes("m3u8")) {
                elem = el;
                if (el.src.includes("m3u8")) {
                    videoType = "m3u8";
                }
                break;
            }
        }
    }
    
    if (elem) {
        videoURL = elem.src;
    }
    
    arguments.completionFunction({"url":url,"videoURL":videoURL,"videoType":videoType});
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