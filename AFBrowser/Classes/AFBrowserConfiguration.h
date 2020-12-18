//
//  AFBrowserConfiguration.h
//  AFBrowser
//
//  Created by alfie on 2020/12/17.
//
//  浏览器的配置

#import <Foundation/Foundation.h>
#import "AFBrowserDelegate.h"
#import "AFPlayer.h"

@interface AFBrowserConfiguration : NSObject

/** 是否有其他第三方APP在播放 */
@property (nonatomic, assign) BOOL                     isOtherAudioPlaying;

/** 当前选中的index */
@property (assign, nonatomic) NSInteger                selectedIndex;

/** 播放方式，默认刚进入浏览器时，如果是视频会自动播放，后续的翻页不会自动播放 */
@property (assign, nonatomic) AFBrowserPlayOption      playOption;

/** 视频转场时，是否使用外部播放器进行转场动画，如果为YES，则视频播放是连续的（前提条件是外部有提供播放器），默认NO */
@property (assign, nonatomic) BOOL                     useCustomPlayer;

/** 播放视频时，是否显示控制条，默认不显示 */
@property (assign, nonatomic) BOOL                     showVideoControl;

/** 播放视频时，是否无限循环播放，默认NO */
@property (assign, nonatomic) BOOL                     infiniteLoop;

/** 转场时，是否隐藏源视图，默认YES */
@property (assign, nonatomic) BOOL                     hideSourceViewWhenTransition;

/** 自定义参数 */
@property (nonatomic, strong) id                       userInfo;

/** 是否屏幕旋转，默认跟随系统 */
@property (nonatomic, assign) AFBrowserRotation        rotation;


/**
 * @brief 获取当前展示的控制器
 */
+ (UIViewController *)currentVc;

@end





