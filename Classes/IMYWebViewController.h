//
//  IMYWebViewController.h
//  IMYADLaunchDemo
//
//  Created by ljh on 16/6/27.
//  Copyright © 2016年 ljh. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IMYWebViewController : UIViewController

@end


@interface UIViewController (IMYPublic)
///该vc的navigationController
- (UINavigationController*)imy_navigationController;
@end
