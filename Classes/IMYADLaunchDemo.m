//
//  IMYADLaunchDemo.m
//  IMYADLaunchDemo
//
//  Created by ljh on 16/6/27.
//  Copyright © 2016年 ljh. All rights reserved.
//

#import "IMYADLaunchDemo.h"
#import "IMYWebViewController.h"

@interface IMYADLaunchDemo ()
@property (nonatomic, strong) UIWindow* window;
@property (nonatomic, assign) NSInteger downCount;
@property (nonatomic, weak) UIButton* downCountButton;
@end

@implementation IMYADLaunchDemo
///在load 方法中，启动监听，可以做到无注入
+ (void)load
{
    [self shareInstance];
}
+ (instancetype)shareInstance
{
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        
        ///如果是没啥经验的开发，请不要在初始化的代码里面做别的事，防止对主线程的卡顿，和 其他情况
        
        ///应用启动, 首次开屏广告
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            ///要等DidFinished方法结束后才能初始化UIWindow，不然会检测是否有rootViewController
            [self checkAD];
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
- (void)request
{
    ///.... 请求新的广告数据
}
- (void)checkAD
{
    ///如果有则显示，无则请求， 下次启动再显示。
    ///我们这里都当做有
    [self show];
}
- (void)show
{
    ///初始化一个Window， 做到对业务视图无干扰。
    UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    window.rootViewController = [UIViewController new];
    window.rootViewController.view.backgroundColor = [UIColor clearColor];
    ///广告布局
    [self setupSubviews:window];
    
    ///设置为最顶层，防止 AlertView 等弹窗的覆盖
    window.windowLevel = UIWindowLevelStatusBar + 1;
    
    ///默认为YES，当你设置为NO时，这个Window就会显示了
    window.hidden = NO;
    window.alpha = 1;
    
    ///防止释放，显示完后  要手动设置为 nil
    self.window = window;
}

- (void)letGo
{
    ///不直接取KeyWindow 是因为当有AlertView 或者有键盘弹出时， 取到的KeyWindow是错误的。
    UIViewController* rootVC = [[UIApplication sharedApplication].delegate window].rootViewController;
    [[rootVC imy_navigationController] pushViewController:[IMYWebViewController new] animated:YES];
    
    [self hide];
}
- (void)goOut
{
    [self hide];
}
- (void)hide
{
    ///来个渐显动画
    [UIView animateWithDuration:0.3 animations:^{
        self.window.alpha = 0;
    } completion:^(BOOL finished) {
        [self.window.subviews.copy enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj removeFromSuperview];
        }];
        self.window.hidden = YES;
        self.window = nil;
    }];
}

///初始化显示的视图， 可以挪到具
- (void)setupSubviews:(UIWindow*)window
{
    ///随便写写
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:window.bounds];
    imageView.image = [UIImage imageNamed:@"adimage.png"];
    imageView.userInteractionEnabled = YES;
    
    ///给非UIControl的子类，增加点击事件
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(letGo)];
    [imageView addGestureRecognizer:tap];
    
    [window addSubview:imageView];
    
    ///增加一个倒计时跳过按钮
    self.downCount = 3;
    
    UIButton * goout = [[UIButton alloc] initWithFrame:CGRectMake(window.bounds.size.width - 100 - 20, 20, 100, 60)];
    [goout setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
    [goout addTarget:self action:@selector(goOut) forControlEvents:UIControlEventTouchUpInside];
    [window addSubview:goout];
    
    self.downCountButton = goout;
    [self timer];
}
- (void)timer
{
    [self.downCountButton setTitle:[NSString stringWithFormat:@"跳过：%ld",(long)self.downCount] forState:UIControlStateNormal];
    if (self.downCount <= 0) {
        [self hide];
    }
    else {
        self.downCount --;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self timer];
        });
    }
}
@end
