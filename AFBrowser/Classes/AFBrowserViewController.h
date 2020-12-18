//
//  AFBrowserViewController.h
//  AFWorkSpace
//
//  Created by alfie on 2019/7/9.
//  Copyright © 2019 Alfie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AFBrowserConfiguration.h"
#import "AFBrowserItem.h"
#import "AFBrowserLoaderDelegate.h"

@interface AFBrowserViewController : UIViewController

/**
 * @brief 设置浏览器的加载器代理
 * @note  如果不设置的话，默认使用 SDWebImage 来加载图片
 * @note  对于加载视频，如果需要做本地缓存，建议设置代理并实现加载方法
 */
@property (nonatomic, class) Class <AFBrowserLoaderDelegate>   loaderProxy;

/** 配置 */
@property (nonatomic, strong, readonly) AFBrowserConfiguration *configuration;

/** 代理 */
@property (weak, nonatomic) id <AFBrowserDelegate>     delegate;

/** 浏览模式，默认不展示顶部的toolBar */
@property (assign, nonatomic) AFBrowserType            browserType;

/** 页码显示类型，默认不显示 */
@property (nonatomic, assign) AFPageControlType        pageControlType;


/**
 * @brief 获取指定index的item数据源
 * @note  如果缓存为空，会从代理方法中取
 */
- (AFBrowserItem *)itemAtIndex:(NSInteger)index;


/**
 * @brief 获取对应类型的方法，给外部调用
 *
 * @param action 方法类型
 */
- (SEL)selectorForAction:(AFBrowserAction)action;


/**
 * @brief 刷新数据
 *
 * @note  先更新外部的数据源，再刷新
 */
- (void)reloadData;


/**
 * @brief 弹出浏览器，开始浏览
 */
- (void)browse;



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


