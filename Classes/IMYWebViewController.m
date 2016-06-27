//
//  IMYWebViewController.m
//  IMYADLaunchDemo
//
//  Created by ljh on 16/6/27.
//  Copyright © 2016年 ljh. All rights reserved.
//

#import "IMYWebViewController.h"

@interface IMYWebViewController ()
@property (nonatomic, strong) UIWebView *webView;
@end

@implementation IMYWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"我是广告";
    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    self.webView.backgroundColor = [UIColor whiteColor];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.cocoachina.com/ios/20160621/16764.html"]]];
    [self.view addSubview:self.webView];
}
@end



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