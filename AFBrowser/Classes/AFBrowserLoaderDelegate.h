//
//  AFBrowserLoaderDelegate.h
//  AFBrowser
//
//  Created by alfie on 2020/9/2.
//

#import <Foundation/Foundation.h>

@class AFBrowserItem;

@protocol AFBrowserLoaderDelegate <NSObject>
@optional;


+ (void)initializeAFBrowserViewController;


/**
 * @brief 从缓存中获取图片
 *
 * @param key   图片地址
 */
+ (UIImage *)imageFromCacheForKey:(NSString *)key;

/// 获取自定义下载视频的路径
+ (NSString *)filePathWithVideoUrl:(NSString *)url;

/**
 * @brief 自定义加载图片
 *
 * @param imageUrl   图片地址
 * @param completion 图片加载完后，需要调用completion(image)来显示
 */
+ (void)loadImage:(NSURL *)imageUrl completion:(void (^)(UIImage *image, NSError *error))completion;


/**
 * @brief 自定义加载视频
 *
 * @param videoUrl   视频地址
 * @param completion 视频加载完后，需要保存到本地，然后调用completion(本地的Url)来展示
 */
+ (void)loadVideo:(NSString *)videoUrl progress:(void (^)(NSProgress *))progress completion:(void (^)(NSString *url, NSError *error))completion;


/**
 * @brief 添加日志
 */
+ (void)addLogString:(NSString *)log;


/**
 * @brief 多语言适配
 * @note  适配文字：查看原图
 */
+ (NSString *)localizedString:(NSString *)string;


/**
 * @brief 浏览器导航控制器的类，默认UINavigationController
 */
+ (Class)navigationControllerClassForBrowser;


/**
 * @brief 统一在视频即将播放前进行拦截，控制是否播放，如果视频本身是不播放的，则无效
 */
+ (BOOL)shouldPlayVideo:(AFBrowserItem *)item;


@end






