//
//  AFBrowserViewController.h
//  AFWorkSpace
//
//  Created by alfie on 2019/7/9.
//  Copyright © 2019 Alfie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AFBrowserItem.h"
#import "AFBrowserDelegate.h"
#import "AFBrowserLoaderDelegate.h"
#import "AFPlayer.h"


@interface AFBrowserViewController : UIViewController

/** 代理 */
@property (weak, nonatomic) id<AFBrowserDelegate>      delegate;

/** 当前选中的index */
@property (assign, nonatomic) NSInteger                selectedIndex;

/** 浏览模式，默认不展示顶部的toolBar */
@property (assign, nonatomic) AFBrowserType            browserType;

/** 页码显示类型，默认不显示 */
@property (nonatomic, assign) AFPageControlType        pageControlType;

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

/**
 * @brief 设置浏览器的加载器代理
 * @note  如果不设置的话，默认使用 SDWebImage 来加载图片
 * @note  对于加载视频，如果需要做本地缓存，建议设置代理并实现加载方法
 */
@property (nonatomic, class) Class <AFBrowserLoaderDelegate>   loaderProxy;

/**
 * @brief 获取指定index的item数据源
 * @note  如果缓存为空，会从代理方法中取
 */
- (AFBrowserItem *)itemAtIndex:(NSInteger)index;

/**
 * @brief 弹出浏览器，开始浏览
 */
- (void)browse;

/**
 * @brief 构造播放器
 */
+ (AFPlayer *)productPlayer;


#pragma mark - 自定义UI
/// 导航栏，用于开发者自定义导航栏样式 和 添加子视图
- (UIView *)toolBar;

/// 退出按钮
- (UIButton *)dismissBtn;

/// 删除按钮
- (UIButton *)deleteBtn;

/// 选择按钮
- (UIButton *)selectBtn;

/// 分页计数器
- (UIPageControl *)pageControl;

/// 分页计数（文本）
- (UILabel *)pageLabel;


#pragma mark - 链式调用
/// 代理
- (AFBrowserViewController * (^)(id <AFBrowserDelegate>))makeDelegate;

/// 当前选中的index
- (AFBrowserViewController * (^)(NSUInteger))makeSelectedIndex;

/// 浏览模式，默认不展示顶部的toolbar
- (AFBrowserViewController * (^)(AFBrowserType))makeBrowserType;

/// 页码显示类型，默认不显示
- (AFBrowserViewController * (^)(AFPageControlType))makePageControlType;

/// 播放方式，默认刚进入浏览器时，如果是视频会自动播放，后续的翻页不会自动播放
- (AFBrowserViewController * (^)(AFBrowserPlayOption))makePlayOption;

/// 视频转场时，是否使用外部播放器进行转场动画，如果为YES，则视频播放是连续的（前提条件是外部有提供播放器），默认NO
- (AFBrowserViewController * (^)(BOOL))makeUseCustomPlayer;

/// 播放视频时，是否显示控制条，默认不显示
- (AFBrowserViewController * (^)(BOOL))makeShowVideoControl;

/// 播放视频时，是否无限循环播放，默认NO
- (AFBrowserViewController * (^)(BOOL))makeInfiniteLoop;

/// 转场时，是否隐藏源视图，默认YES
- (AFBrowserViewController * (^)(BOOL))makeHideSourceViewWhenTransition;

/// 自定义参数，在代理回调中可以作为一个标识
- (AFBrowserViewController * (^)(id))makeUserInfo;




@end


