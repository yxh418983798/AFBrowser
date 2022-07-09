//
//  AFBrowserConfiguration.m
//  AFBrowser
//
//  Created by alfie on 2020/12/17.
//

#import "AFBrowserConfiguration.h"
#import "AFBrowserItem.h"
#import "AFDownloader.h"
#import "AFBrowserViewController.h"

@interface AFBrowserConfiguration ()

@end

@implementation AFBrowserConfiguration

static UIDeviceOrientation *_lastOrientation;
+ (void)load {
    _lastOrientation = UIDeviceOrientationPortrait;
}

+ (void)initialize {
    //        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(deviceOrientationDidChangeNotification) name:UIDeviceOrientationDidChangeNotification object:nil];
}
#pragma mark - 构造
- (instancetype)init {
    if (self = [super init]) {
        self.selectedIndex = 0;
        self.autoLoadOriginalImage = YES;
        self.videoGravity = AVLayerVideoGravityResizeAspectFill;
        self.shouldBrowseWhenNoCache = YES;
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
- (AFBrowserConfiguration * (^)(id <AFBrowserDelegate>))makeDelegate {
    return ^id(id <AFBrowserDelegate> delegate) {
        self.delegate = delegate;
        return self;
    };
}

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

- (AFBrowserConfiguration * (^)(BOOL))makeHideSourceViewWhenTransition {
    return ^id(BOOL hideSourceViewWhenTransition) {
        self.hideSourceViewWhenTransition = hideSourceViewWhenTransition;
        return self;
    };
}

/// 资源未加载成功是否跳转到浏览器，默认NO
- (AFBrowserConfiguration * (^)(BOOL))makeShouldBrowseWhenNoCache {
    return ^id(BOOL shouldBrowseWhenNoCache) {
        self.shouldBrowseWhenNoCache = shouldBrowseWhenNoCache;
        return self;
    };
}

- (AFBrowserConfiguration * (^)(id))makeUserInfo {
    return ^id(id userInfo) {
        self.userInfo = userInfo;
        return self;
    };
}

/// 播放器填充方式
- (AFBrowserConfiguration * (^)(AVLayerVideoGravity))makeVideoGravity {
    return ^id(AVLayerVideoGravity videoGravity) {
        self.videoGravity = videoGravity;
        return self;
    };
}



//#pragma mark - 旋转屏幕的通知
+ (void)deviceOrientationDidChangeNotification {
    // 旋转之后当前的设备方向
    UIDeviceOrientation orient = UIDevice.currentDevice.orientation;
//    NSLog(@"-------------------------- 收到屏幕旋转的通知：%d --------------------------", orient);
    if (orient == UIDeviceOrientationUnknown) orient = UIDeviceOrientationPortrait;
    if (UIDeviceOrientationIsFlat(orient)) return;
    if (_lastOrientation == orient) return;
    _lastOrientation = orient;

//    if (self.supportedInterfaceOrientations == UIInterfaceOrientationMaskPortrait && self.lastOrientation == UIDeviceOrientationPortrait) {
//        return;
//    }

//    switch (orient) {
//        case UIDeviceOrientationPortrait:
//            if (self.supportedInterfaceOrientations & UIInterfaceOrientationMaskPortrait) {
//                self.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height);
//            }
//            break;
//
//        case UIDeviceOrientationLandscapeLeft:
//            if (self.supportedInterfaceOrientations & UIInterfaceOrientationMaskLandscapeLeft) {
//                self.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height);
//            }
//            break;
//
//        case UIDeviceOrientationPortraitUpsideDown:
//            if (self.supportedInterfaceOrientations & UIInterfaceOrientationMaskPortraitUpsideDown) {
//                self.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height);
//            }
//            break;
//
//        case UIDeviceOrientationLandscapeRight:
//            if (self.supportedInterfaceOrientations & UIInterfaceOrientationMaskLandscapeRight) {
//                self.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height);
//            }
//            break;
//
//        default:
//            break;
//    }

}

+ (BOOL)isPortrait {
    return UIDeviceOrientationIsPortrait(_lastOrientation);
}


#pragma mark - 查询视频缓存
- (NSString *)videoPathForItem:(AFBrowserItem *)item {
    NSString *key = [item.content isKindOfClass:NSString.class] ? item.content : [(NSURL *)item.content absoluteString];
    if ([key containsString:@"/var/mobile"]) {
        if ([key hasPrefix:@"file:///"]) key = [key substringFromIndex:7];
        return [NSFileManager.defaultManager fileExistsAtPath:key] ? key : nil;
    }
    NSString *path;
    if ([self.delegate respondsToSelector:@selector(browser:videoPathWithKey:atIndex:)]) {
        path = [self.delegate browser:self videoPathForItem:item];
    }
    if (!path) path = [AFDownloader videoPathWithUrl:key];
    return path;
}


- (BOOL)isEqualUrl:(NSString *)url toUrl:(NSString *)toUrl {
    NSString *urlString = url;
    if ([urlString hasPrefix:@"file:///"]) {
        urlString = [urlString substringFromIndex:7];
    }
    NSString *toUrlString = toUrl;
    if ([toUrlString hasPrefix:@"file:///var"]) {
        toUrlString = [toUrlString substringFromIndex:7];
    }
    return [urlString isEqualToString:toUrlString];
}


- (BOOL)isBrowsed {
    if (!_browserVc) return NO;
    return _isBrowsed;
}


- (AFBrowserItem *)currentItem {
    if (self.browserVc) return [self.browserVc itemAtIndex:self.selectedIndex];
    return [self.delegate browser:nil itemForBrowserAtIndex:self.selectedIndex];
}


@end

