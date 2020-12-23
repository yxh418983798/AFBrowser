//
//  AFBrowserConfiguration.h
//  AFBrowser
//
//  Created by alfie on 2020/12/17.
//
//  浏览器的配置

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "AFBrowserEnum.h"
#import "AFBrowserDelegate.h"

@interface AFBrowserConfiguration : NSObject

/** 代理 */
@property (weak, nonatomic) id <AFBrowserDelegate>     delegate;

/** 资源未加载成功是否跳转到浏览器，默认NO */
@property (assign, nonatomic) BOOL                     shouldBrowseWhenNoCache;

/** 是否自动加载原图，默认YES */
@property (assign, nonatomic) BOOL                     autoLoadOriginalImage;

/** 播放视频时，是否显示控制条，默认NO */
@property (assign, nonatomic) BOOL                     showVideoControl;

/** 播放视频时，是否无限循环播放，默认NO */
@property (assign, nonatomic) BOOL                     infiniteLoop;

/** 转场时，是否隐藏源视图，默认YES */
@property (assign, nonatomic) BOOL                     hideSourceViewWhenTransition;

/** 是否有其他第三方APP在播放 */
@property (nonatomic, assign) BOOL                     isOtherAudioPlaying;

/** 当前选中的index */
@property (assign, nonatomic) NSInteger                selectedIndex;

/** 静音播放方式，默认不静音 */
@property (nonatomic, assign) AFPlayerMuteOption       muteOption;

/** 转场方式 */
@property (assign, nonatomic) AFBrowserTransitionStyle transitionStyle;

/** 播放方式，默认刚进入浏览器时，如果是视频会自动播放，后续的翻页不会自动播放 */
@property (assign, nonatomic) AFBrowserPlayOption      playOption;

/** 是否屏幕旋转，默认跟随系统 */
@property (nonatomic, assign) AFBrowserRotation        rotation;

/** 浏览模式，默认不展示顶部的toolBar */
@property (assign, nonatomic) AFBrowserType            browserType;

/** 页码显示类型，默认不显示 */
@property (nonatomic, assign) AFPageControlType        pageControlType;

/** 自定义参数 */
@property (nonatomic, strong) id                       userInfo;

/** 播放器的填充方式，默认AVLayerVideoGravityResizeAspectFill完全填充 */
@property (nonatomic, copy) AVLayerVideoGravity        videoGravity;

/**
 * @brief 获取当前展示的控制器
 */
+ (UIViewController *)currentVc;

+ (BOOL)isPortrait;

#pragma mark - 链式调用
/// 代理
- (AFBrowserConfiguration * (^)(id <AFBrowserDelegate>))makeDelegate;

/// 当前选中的index
- (AFBrowserConfiguration * (^)(NSUInteger))makeSelectedIndex;

/// 浏览模式，默认不展示顶部的toolbar
- (AFBrowserConfiguration * (^)(AFBrowserType))makeBrowserType;

/// 页码显示类型，默认不显示
- (AFBrowserConfiguration * (^)(AFPageControlType))makePageControlType;

/// 播放方式，默认刚进入浏览器时，如果是视频会自动播放，后续的翻页不会自动播放
- (AFBrowserConfiguration * (^)(AFBrowserPlayOption))makePlayOption;

/// 播放器的静音方式
- (AFBrowserConfiguration * (^)(AFPlayerMuteOption))makeMuteOption;

/// 视频转场时，是否使用外部播放器进行转场动画，如果为YES，则视频播放是连续的（前提条件是外部有提供播放器），默认NO
- (AFBrowserConfiguration * (^)(AFBrowserTransitionStyle))makeTransitionStyle;

/// 播放视频时，是否显示控制条，默认不显示
- (AFBrowserConfiguration * (^)(BOOL))makeShowVideoControl;

/// 播放视频时，是否无限循环播放，默认NO
- (AFBrowserConfiguration * (^)(BOOL))makeInfiniteLoop;

/// 转场时，是否隐藏源视图，默认YES
- (AFBrowserConfiguration * (^)(BOOL))makeHideSourceViewWhenTransition;

/// 资源未加载成功是否跳转到浏览器，默认NO
- (AFBrowserConfiguration * (^)(BOOL))makeShouldBrowseWhenNoCache;

/// 自定义参数，在代理回调中可以作为一个标识
- (AFBrowserConfiguration * (^)(id))makeUserInfo;

/// 播放器填充方式
- (AFBrowserConfiguration * (^)(AVLayerVideoGravity))makeVideoGravity;



@end





