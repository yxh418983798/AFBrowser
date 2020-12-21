//
//  AFBrowserConfiguration.m
//  AFBrowser
//
//  Created by alfie on 2020/12/17.
//

#import "AFBrowserConfiguration.h"

@implementation AFBrowserConfiguration

#pragma mark - 构造
- (instancetype)init {
    if (self = [super init]) {
        self.selectedIndex = 0;
        self.hideSourceViewWhenTransition = YES;
        self.autoLoadOriginalImage = YES;
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


#pragma mark - 链式调用
- (AFBrowserConfiguration * (^)(NSUInteger))makeSelectedIndex {
    return ^id(NSUInteger selectedIndex) {
        self.selectedIndex = selectedIndex;
        return self;
    };
}

- (AFBrowserConfiguration * (^)(AFBrowserType))makeBrowserType {
    return ^id(AFBrowserType browserType) {
        self.browserType = browserType;
        return self;
    };
}

- (AFBrowserConfiguration * (^)(AFPageControlType))makePageControlType {
    return ^id(AFPageControlType pageControlType) {
        self.pageControlType = pageControlType;
        return self;
    };
}

- (AFBrowserConfiguration * (^)(AFBrowserPlayOption))makePlayOption {
    return ^id(AFBrowserPlayOption playOption) {
        self.playOption = playOption;
        return self;
    };
}

- (AFBrowserConfiguration * (^)(AFPlayerMuteOption))makeMuteOption {
    return ^id(AFPlayerMuteOption muteOption) {
        self.muteOption = muteOption;
        return self;
    };
}

- (AFBrowserConfiguration * (^)(AFBrowserTransitionStyle))makeTransitionStyle {
    return ^id(AFBrowserTransitionStyle transitionStyle) {
        self.transitionStyle = transitionStyle;
        return self;
    };
}

- (AFBrowserConfiguration * (^)(BOOL))makeShowVideoControl {
    return ^id(BOOL showVideoControl) {
        self.showVideoControl = showVideoControl;
        return self;
    };
}

- (AFBrowserConfiguration * (^)(BOOL))makeInfiniteLoop {
    return ^id(BOOL infiniteLoop) {
        self.infiniteLoop = infiniteLoop;
        return self;
    };
}

- (AFBrowserConfiguration * (^)(BOOL))makeHideSourceViewWhenTransition {
    return ^id(BOOL hideSourceViewWhenTransition) {
        self.hideSourceViewWhenTransition = hideSourceViewWhenTransition;
        return self;
    };
}

- (AFBrowserConfiguration * (^)(id))makeUserInfo {
    return ^id(id userInfo) {
        self.userInfo = userInfo;
        return self;
    };
}


@end
