//
//  AFBrowserDelegate.h
//  AFBrowser
//
//  Created by alfie on 2020/9/3.
//

#import <Foundation/Foundation.h>
#import "AFBrowserEnum.h"

@class AFBrowserItem, AFBrowserViewController;

@protocol AFBrowserDelegate <NSObject>


/**
 * @brief 必须实现， 返回item的数量
 */
- (NSInteger)numberOfItemsInBrowser:(AFBrowserViewController *)browser;


/**
 * @brief 构造item数据源
 *
 * @note  内部会自动缓存item，
 */
- (AFBrowserItem *)browser:(AFBrowserViewController *)browser itemForBrowserAtIndex:(NSInteger)index;


@optional;

/**
 * @brief 返回转场的View
 *
 * @note  如果是图片的类型，应该返回该图片所在的UIImageView
 * @note  如果是视频的类型，应该返回视频播放器的容器View
 */
- (UIView *)browser:(AFBrowserViewController *)browser viewForTransitionAtIndex:(NSInteger)index;


/**
 * @brief 返回转场的图片
 *
 * @note  当 viewForTransitionAtIndex 返回的是一个自定义的View，无法准确的获取到image，此时需要实现该方法返回一张图片
 * @note  如果没有实现该方法，内部会自动使用 viewForTransitionAtIndex 返回的View的截图
 */
- (UIImage *)browser:(AFBrowserViewController *)browser imageForTransitionAtIndex:(NSInteger)index;


/**
 * @brief 返回是否自动下载原图，该方法优先级高于 AFBrowserConfiguration的autoLoadOriginalImage
 *
 * @param index 触发的index，只有图片类型的item会触发，如果已经下载过原图，不会触发该方法
 * @return 如果返回YES，不会显示查看原图的按钮，并自动下载原图
 * @return 如果返回NO，则在未下载原图的情况，优先展示缩略图和查看原图按钮，点击后下载原图并展示
 */
- (BOOL)browser:(AFBrowserViewController *)browser shouldAutoLoadOriginalImageForItemAtIndex:(NSInteger)index;


/**
 * @brief 长按cell事件
 *
 * @param index 触发长按的index
 */
- (void)browser:(AFBrowserViewController *)browser longPressActionAtIndex:(NSInteger)index;


/**
 * @brief 删除事件
 *
 * @param index 触发删除的index
 * @param completionDelete 删除的执行函数
 * @note  该方法在用户点击删除按钮时调用，开发者可以在这里进行事件的预处理
 * 比如更新数据、弹窗提示用户是否确认删除等，当用户确认删除时，需要调用completionDelete()的block来通知browser删除数据并更新UI */
- (void)browser:(AFBrowserViewController *)browser deleteActionAtIndex:(NSInteger)index completionDelete:(void (^)(void))completionDelete;


/**
 * @brief 自定义浏览器Cell的UI
 *
 * @warning 这个方法应只用来添加cell的subView，不要对原有视图进行变更或移除
 * @param cell 展示的容器，将想要自定义的UI添加到cell
 * @note  该方法会在每次cell出现时都调用一次，内部会自动删除添加过的视图
 * @note  如果自定义的视图，有涉及到Browser的内部事件操作，可以使用selectorForAction来添加事件，例如：
 *        [btn addTarget:browser action:[browser selectorForAction:AFBrowserActionDelete] forControlEvents:(UIControlEventTouchUpInside)];
          [cell addSubview:btn];
 */
- (void)browser:(AFBrowserViewController *)browser willDisplayCell:(UICollectionViewCell *)cell forItemAtIndex:(NSInteger)index;


/**
 * @brief 自定义浏览器的UI
 */
- (void)viewDidLoadBrowser:(AFBrowserViewController *)browser;


/**
 * @brief dismiss控制器的回调
 *
 * @note  如果频的类型，应该返回视频播放器的容器View
 */
- (void)didDismissBrowser:(AFBrowserViewController *)browser;


/**
 * @brief 分页加载数据的实现，每次浏览到第一个或最后一个Item时，自动调用该方法获取数据
 *
 * @param direction  翻页方向
 * @param completionReload 数据加载完成后，需要调用completionReload(YES)刷新，之后AFBrowser会重新从 itemForBrowserAtIndex: 方法获取数据源
 * @note  如果Item的数据量很大，建议实现该协议来分页加载数据源，以提升性能
 * @note  success 表示数据是否成功加载完毕，如果传了NO，是不会刷新数据的
 */
- (void)browser:(AFBrowserViewController *)browser loadDataWithDirection:(AFBrowserDirection)direction completionReload:(void (^)(BOOL success))completionReload;


/**
 * @brief 自定义加载图片
 */
- (void)browser:(AFBrowserViewController *)browser loadImage:(NSString *)image;


/**
 * @brief 自定义加载图片
 */
- (void)browser:(AFBrowserViewController *)browser loadVideo:(NSString *)video;


/**
 * @brief 查询图片缓存，如果没有实现，会从AFBrowserLoaderDelegate方法中查询
 */
- (UIImage *)browser:(AFBrowserViewController *)browser hasImageCacheWithKey:(NSString *)key atIndex:(NSInteger)index;


/**
 * @brief 查询视频缓存的本地路径，如果没有实现，会从AFBrowserLoaderDelegate方法中查询
 */
- (NSString *)browser:(AFBrowserViewController *)browser videoPathWithKey:(NSString *)key atIndex:(NSInteger)index;

@end

