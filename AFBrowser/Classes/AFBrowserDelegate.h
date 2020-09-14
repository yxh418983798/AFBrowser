//
//  AFBrowserDelegate.h
//  AFBrowser
//
//  Created by alfie on 2020/9/3.
//

#import <Foundation/Foundation.h>

@class AFBrowserViewController;
@class AFBrowserItem;

/// 浏览模式
typedef NS_ENUM(NSUInteger, AFBrowserType){
    AFBrowserTypeDefault,  // 浏览模式，没有操作
//    AFBrowserTypeSelect,   // 选择模式，可以选中图片
    AFBrowserTypeDelete,   // 删除模式，可以删除图片
};

/// 显示页码的方式
typedef NS_ENUM(NSUInteger, AFPageControlType){
    AFPageControlTypeNone,    // 不显示页码
    AFPageControlTypeCircle,  // 小圆点
    AFPageControlTypeText,    // 文字
};

/// 播放器的播放方式
typedef NS_ENUM(NSUInteger, AFBrowserPlayOption){
    AFBrowserPlayOptionDefault,       /// 默认，刚进入浏览器时，如果是视频会自动播放，后续的翻页不会自动播放
    AFBrowserPlayOptionAutoPlay,      /// 自动播放，放大浏览和翻页切换视频的时候都会自动播放
    AFBrowserPlayOptionNeverAutoPlay, /// 不自动播放，只能通过 点击播放按钮 来播放视频
};

/// 翻页的方向
typedef NS_ENUM(NSUInteger, AFBrowserDirection){
    AFBrowserDirectionLeft,   // 向左翻页
    AFBrowserDirectionRight,  // 向右翻页
};


@protocol AFBrowserDelegate <NSObject>


/**
 * @brief 必须实现， 返回item的数量
 */
- (NSInteger)numberOfItemsInBrowser:(AFBrowserViewController *)browser;


/**
 * @brief 构造item数据源
 * @note  内部会自动缓存item，
 */
- (AFBrowserItem *)browser:(AFBrowserViewController *)browser itemForBrowserAtIndex:(NSInteger)index;



@optional;


/**
 * @brief 长按cell事件
 *
 * @param index 触发长按的index
 */
- (void)browser:(AFBrowserViewController *)browser longPressActionAtIndex:(NSInteger)index;


/**
 * @brief 删除事件
 * @note  该方法在用户点击删除按钮时调用，开发者可以在这里进行事件的预处理
 * 比如更新数据、弹窗提示用户是否确认删除等，当用户确认删除时，需要调用completionDelete()的block来通知browser删除数据并更新UI
 *
 * @param index 触发删除的index
 * @param completionDelete 删除的执行函数，
 */
- (void)browser:(AFBrowserViewController *)browser deleteActionAtIndex:(NSInteger)index completionDelete:(void (^)(void))completionDelete;


/**
 * @brief 返回转场的View
 * @note  如果是图片的类型，应该返回该图片所在的UIImageView
 * @note  如果是视频的类型，应该返回视频播放器的容器View
 */
- (UIView *)browser:(AFBrowserViewController *)browser viewForTransitionAtIndex:(NSInteger)index;


/**
 * @brief 分页加载数据的实现，每次浏览到第一个或最后一个Item时，自动调用该方法获取数据
 * @note  如果Item的数据量很大，建议实现该协议来分页加载数据源，以提升性能
 *
 * @param direction  翻页方向
 * @param completionReload 数据加载完成后，需要调用completionReload(YES)刷新，之后AFBrowser会重新从 itemForBrowserAtIndex: 方法获取数据源
 * @note  success 表示数据是否成功加载完毕，如果传了NO，是不会刷新数据的
 */
- (void)loadDataWithDirection:(AFBrowserDirection)direction completionReload:(void (^)(BOOL success))completionReload;


/**
 * @brief dismiss控制器的回调
 *
 * @note  如果频的类型，应该返回视频播放器的容器View
 */
- (void)didDismissBrowser:(AFBrowserViewController *)browser;

@end

