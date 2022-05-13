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


#pragma mark - 数据源相关

/**
 * @brief 返回item的数量
 */
- (NSInteger)numberOfItemsInBrowser:(AFBrowserViewController *)browser;

/**
 * @brief 构造item数据源，AFBrowser会自动缓存item
 */
- (AFBrowserItem *)browser:(AFBrowserViewController *)browser itemForBrowserAtIndex:(NSInteger)index;


@optional;

/**
 * @brief 返回item的总数量
 *
 * @discussion
 * 当使用分页加载数据时，可通过实现该方法，展示总数量
 * 如果不实现该方法，页面总数量为 <numberOfItemsInBrowser:>
 */
- (NSInteger)totalNumberOfItemsInBrowser:(AFBrowserViewController *)browser;

/**
 * @brief 返回是否自动下载原图
 *
 * @return YES，不显示查看原图的按钮，并自动下载原图
 * @return NO，在未下载原图的情况，优先展示缩略图和查看原图按钮，用户点击查看原图按钮后，再自动下载原图并展示
 *
 * @discussion
 * 只有图片类型的item会触发该方法，如果已经下载过原图，不会触发该方法
 * 该方法优先级高于 AFBrowserConfiguration的autoLoadOriginalImage
 */
- (BOOL)browser:(AFBrowserViewController *)browser shouldAutoLoadOriginalImageForItemAtIndex:(NSInteger)index;

/**
 * @brief 自定义查询图片缓存，如果没有实现，会从AFBrowserLoaderDelegate方法中查询
 */
- (UIImage *)browser:(AFBrowserViewController *)browser hasImageCacheWithKey:(NSString *)key atIndex:(NSInteger)index;

/**
 * @brief 自定义查询视频缓存的本地路径，如果没有实现，会从AFBrowserLoaderDelegate方法中查询
 */
- (NSString *)browser:(AFBrowserViewController *)browser videoPathForItem:(AFBrowserItem *)item;

/**
 * @brief 视频下载失败
 */
- (void)browser:(AFBrowserViewController *)browser loadVideoFailed:(AFBrowserItem *)item error:(NSError *)error;


#pragma mark - 转场相关

/**
 * @brief 返回转场的View
 *
 * @discussion
 * 如果是图片的类型，应该返回该图片所在的UIImageView
 * 如果是视频的类型，应该返回视频播放器的容器View
 */
- (UIView *)browser:(AFBrowserViewController *)browser viewForTransitionAtIndex:(NSInteger)index;

/**
 * @brief 返回转场的图片
 *
 * @discussion
 * 当 <browser:viewForTransitionAtIndex:> 返回的是一个自定义的View，无法准确的获取到image，此时需要实现该方法返回一张图片
 * 如果没有实现该方法且转场的View不是一个UIImageView，内部会自动使用 viewForTransitionAtIndex 返回的View的截图作为转场图片
 */
- (UIImage *)browser:(AFBrowserViewController *)browser imageForTransitionAtIndex:(NSInteger)index;


#pragma mark - 自定义UI

/**
 * @brief 构造浏览器的导航控制器
 */
- (UINavigationController *)navigationControllerForBrowser:(AFBrowserViewController *)browser;

/**
 * @brief 返回图片加载中的占位图
 */
- (UIImage *)browser:(AFBrowserViewController *)browser imageForPlaceholderAtIndex:(NSInteger)index;

/**
 * @brief 配置浏览器的CollectionView，可用于配置UI相关或分页加载
 */
- (void)browser:(AFBrowserViewController *)browser configCollectionView:(UICollectionView *)collectionView;

/**
 * @brief 自定义浏览器Cell的UI
 *
 * @warning 这个方法应只用来添加cell的subView，不要对原有视图进行变更或移除
 * @param cell 展示的容器，将想要自定义的UI添加到cell
 *
 * @discussion
 * 每次cell出现时都会调用一次，内部会自动删除添加过的视图
 * 子视图不会跟随图片等比例伸缩和移动
 * 在转场过程中，Browser会忽略添加的子视图，如果不想忽略，请实现 <willDisplayImageView> 方法
 * 如果自定义的视图，有涉及到Browser的内部事件操作，可以使用selectorForAction来添加事件，例如：
 * @example
 * [btn addTarget:browser action:[browser selectorForAction:AFBrowserActionDelete] forControlEvents:(UIControlEventTouchUpInside)];
 * [cell addSubview:btn];
 */
- (void)browser:(AFBrowserViewController *)browser willDisplayCell:(UICollectionViewCell *)cell forItemAtIndex:(NSInteger)index;

/**
 * @brief 自定义浏览器图片容器的UI
 *
 * @warning 这个方法应只用来添加subView，不要对原有视图进行变更或移除
 * @param containView 图片展示的容器，将想要自定义的UI添加到containView
 *
 * @discussion
 * 该方法会在每次cell出现时都调用一次，内部会自动删除添加过的视图
 * 子视图会跟随图片等比例伸缩和移动
 * 转场过程中，Browser会将自定义视图一起加入到转场，如果不想加入转场，请实现 <willDisplayCell> 方法
 */
- (void)browser:(AFBrowserViewController *)browser willDisplayImageContainView:(UIView *)containView forItemAtIndex:(NSInteger)index;

///**
// * @brief 自定义图片处理
// *
// * @param image 浏览器即将展示的图片
// *
// * @discussion
// * 该方法用于对要展示的图片做自定义处理，例如添加水印，遮罩等
// * 在缩略图和原图加载完成时分别会调用一次
// * 处理完图片之后，需要返回一张新的图片用于展示
// * 在图片处理完成之前，浏览器会先使用一张占位图来展示
// */
//- (UIImage *)browser:(AFBrowserViewController *)browser willDisplayImage:(UIImage *)image forItemAtIndex:(NSInteger)index;


#pragma mark - 交互相关

/**
 * @brief 返回是否允许缩放操作
 */
- (BOOL)browser:(AFBrowserViewController *)browser shouldZoomItemAtIndex:(NSInteger)index;

/**
 * @brief  单击cell事件
 * @return 返回一个BOOL值，是否继续执行Browser默认的点击事件
 */
- (BOOL)browser:(AFBrowserViewController *)browser tapActionAtIndex:(NSInteger)index;

/**
 * @brief 长按cell事件
 */
- (void)browser:(AFBrowserViewController *)browser longPressActionAtIndex:(NSInteger)index;

/**
 * @brief 删除事件
 *
 * @param index 触发删除的index
 * @param completionDelete 删除的执行函数
 *
 * @discussion
 * 该方法在用户点击删除按钮时调用
 * 开发者可以在这里进行事件的预处理，比如更新数据、弹窗提示用户是否确认删除等
 * 当用户确认删除时，需要调用completionDelete()的block来通知browser删除数据并更新UI
 */
- (void)browser:(AFBrowserViewController *)browser deleteActionAtIndex:(NSInteger)index completionDelete:(void (^)(void))completionDelete;

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
 * @brief 点击查看原图，下载完成的回调
 */
- (void)browser:(AFBrowserViewController *)browser didCompletedDownloadOriginalImageItem:(AFBrowserItem *)item error:(NSError *)error;

/**
 * @brief 监听滚动回调
 */
- (void)browser:(AFBrowserViewController *)browser didScroll:(UIScrollView *)scrollView atIndex:(NSInteger)index;

/**
 * @brief 控制浏览器的左右滑动手势
 */
- (BOOL)browser:(AFBrowserViewController *)browser gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)pan;


#pragma mark - 生命周期

/**
 * @brief 浏览器加载完成，可以在这里自定义浏览器的UI
 */
- (void)viewDidLoadBrowser:(AFBrowserViewController *)browser;

/**
 * @brief 浏览器出现
 */
- (void)viewDidAppearBrowser:(AFBrowserViewController *)browser;

/**
 * @brief 浏览器消失
 */
- (void)viewDidDisappearBrowser:(AFBrowserViewController *)browser;

/**
 * @brief dismiss控制器的回调
 *
 * @note  如果频的类型，应该返回视频播放器的容器View
 */
- (void)didDismissBrowser:(AFBrowserViewController *)browser;

/**
 * @brief 开始播放视频的回调
 */
- (void)browser:(AFBrowserViewController *)browser willPlayVideoItem:(AFBrowserItem *)item;


@end


