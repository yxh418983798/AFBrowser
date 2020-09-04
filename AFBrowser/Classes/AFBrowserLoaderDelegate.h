//
//  AFBrowserLoaderDelegate.h
//  AFBrowser
//
//  Created by alfie on 2020/9/2.
//

#import <Foundation/Foundation.h>


@protocol AFBrowserLoaderDelegate <NSObject>


/**
 * @brief 自定义加载图片
 *
 * @param imageUrl   图片地址
 * @param completion 图片加载完后，需要调用completion(image)来显示
 */
+ (void)loadImage:(NSURL *)imageUrl completion:(void (^)(UIImage *))completion;


/**
 * @brief 自定义加载视频
 *
 * @param videoUrl   视频地址
 * @param completion 视频加载完后，需要保存到本地，然后调用completion(本地的Url)来展示
 */
+ (void)loadVideo:(NSURL *)videoUrl completion:(void (^)(NSURL *))completion;


@end






