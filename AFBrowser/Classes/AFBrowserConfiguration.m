//
//  AFBrowserConfiguration.m
//  AFBrowser
//
//  Created by alfie on 2020/12/17.
//

#import "AFBrowserConfiguration.h"

@implementation AFBrowserConfiguration

- (instancetype)init {
    if (self = [super init]) {
        self.selectedIndex = 0;
        self.hideSourceViewWhenTransition = YES;
    }
    return self;
}


#pragma mark - 获取 currentVc
+ (UIViewController *)currentVc {
    UIWindow *window = UIApplication.sharedApplication.delegate.window;
    UIViewController *result = window.rootViewController;
    while (result.presentedViewController) result = result.presentedViewController;
    while ([result isKindOfClass:UITabBarController.class] || [result isKindOfClass:UINavigationController.class]) {
        if ([result isKindOfClass:UITabBarController.class]) {
            result = [(UITabBarController *)result selectedViewController];
            while (result.presentedViewController) result = result.presentedViewController;
        } else if ([result isKindOfClass:UINavigationController.class]) {
            result = [(UINavigationController *)result childViewControllers].lastObject;
            while (result.presentedViewController) result = result.presentedViewController;
        }
    }
    return result;
}


@end
