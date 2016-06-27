《优雅的插入开屏广告》-- 不改动任何一行代码
=============================================

这个框架已经在`美柚`稳定使用半年多了，美柚总用户突破1亿，日活接近千万，代码的稳定性是可以放心的。有需求或者bug可以提issues，我会尽快回复。

![](http://www.meiyou.com/g/images/logo1.png)

最近在CocoaChina上看到蛮多小伙伴分享了自己的开屏广告经验和代码。
[分分钟解决iOS开发中App启动广告的功能](http://www.cocoachina.com/ios/20160615/16652.html)，
[App启动加载广告页面思路](http://www.cocoachina.com/ios/20160614/16671.html)

代码还是不错的，但是个人觉得，上诉代码的耦合性还是太强了，需要对 AppDelegate 和 ViewController 等代码进行入侵。如果按照模块化方式来开发，后续广告要扩展和维护都是很艰难的，因为你要担心你埋入的那些代码被其他人员改动了。 

下面是我使用的一套方案。真正做到模块化，即插即用！

## 实现原理

### 自启动 & 监听

```objective-c
///在load 方法中，启动监听，可以做到无注入
+ (void)load
{
    [self shareInstance];
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        
        ///如果是没啥经验的开发，请不要在初始化的代码里面做别的事，防止对主线程的卡顿，和 其他情况
        
        ///应用启动, 首次开屏广告
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            ///要等DidFinished方法结束后才能初始化UIWindow，不然会检测是否有rootViewController
            dispatch_async(dispatch_get_main_queue(), ^{
               [self checkAD]; 
            });
        }];
        ///进入后台
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            [self request];
        }];
        ///后台启动,二次开屏广告
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            [self checkAD];
        }];
    }
    return self;
}
```

iOS的通知是一个神器，它会发出应用的启动，退到后台等事件通知，有了通知我们就可以做到对AppDelegate的无入侵。

只有通知还是没有用的，我们还需要显示。

### 核心突破点：显示

```objective-c
- (void)show
{
    ///初始化一个Window， 做到对业务视图无干扰。
    UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    
    ///广告布局
    [self setupSubviews:window];
    
    ///设置为最顶层，防止 AlertView 等弹窗的覆盖
    window.windowLevel = UIWindowLevelStatusBar + 1;
    
    ///默认为YES，当你设置为NO时，这个Window就会显示了
    window.hidden = NO;
    
    ///来个渐显动画
    window.alpha = 0;
    [UIView animateWithDuration:0.3 animations:^{
        window.alpha = 1;
    }];
    
    ///防止释放，显示完后  要手动设置为 nil
    self.window = window;
}
```

其实大家一般盖视图，习惯在 KeyWindow 上直接AddSubview， 其实这是不好的。首先KeyWindow 会被AlertView覆盖， 还有可能别的业务代码也进行了AddSubview 这样就会把你的广告给覆盖了。  

而使用我这种 UIWindow 的初始化，可以让你的视图出现在最顶层，不用怕`乱七八糟`的业务逻辑覆盖。

调用KeyWindow 还有个坏处。下面会说到。
 
### 跳转

其实倒计时跟跳转是个很普通的功能点，没啥说的。有个关键点还是要说的 就是KeyWindow的调用

```objective-c
///不直接取KeyWindow 是因为当有AlertView 或者有键盘弹出时， 取到的KeyWindow是错误的。
    UIViewController* rootVC = [[UIApplication sharedApplication].delegate window].rootViewController;
    [[rootVC imy_navigationController] pushViewController:[IMYWebViewController new] animated:YES];
    
```

其实  `[UIApplication sharedApplication].keyWindow` 取到的Window 不一定是你想要的。 因为KeyWindow 是会变的，所以劲量使用 `[Delegate Window] ` 来获取显示的Window。 做 OS X 的应该体会多点。


在送上一个扩展，获取任意ViewController的navigationController

```objective-c
@implementation UIViewController (IMYPublic)
- (UINavigationController*)imy_navigationController
{
    UINavigationController* nav = nil;
    if ([self isKindOfClass:[UINavigationController class]]) {
        nav = (id)self;
    }
    else {
        if ([self isKindOfClass:[UITabBarController class]]) {
            nav = [((UITabBarController*)self).selectedViewController imy_navigationController];
        }
        else {
            nav = self.navigationController;
        }
    }
    return nav;
}
@end
```

demo(gif图，会动的。。)

![](https://raw.githubusercontent.com/li6185377/IMYADLaunchDemo/master/screenshot/ad_launch_demo.gif)