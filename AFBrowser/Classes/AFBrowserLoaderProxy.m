//
//  AFBrowserLoaderProxy.m
//  AFBrowser
//
//  Created by alfie on 2020/9/2.
//

#import "AFBrowserLoaderProxy.h"
#import "UIImageView+WebCache.h"
#import "AFBrowserViewController.h"

@implementation AFBrowserLoaderProxy

#pragma mark - 加载图片，默认使用SD
+ (void)loadImage:(NSURL *)imageUrl completion:(void (^)(UIImage *))completion {
    if (AFBrowserViewController.loaderProxy && AFBrowserViewController.loaderProxy != AFBrowserLoaderProxy.class) {
        [AFBrowserViewController.loaderProxy loadImage:imageUrl completion:completion];
    } else {
        [SDWebImageManager.sharedManager loadImageWithURL:imageUrl options:kNilOptions progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
            completion(image);
        }];
    }
}


#pragma mark - 加载视频，暂未处理
+ (void)loadVideo:(NSURL *)videoUrl completion:(void (^)(NSURL *))completion {
    if (AFBrowserViewController.loaderProxy && AFBrowserViewController.loaderProxy != AFBrowserLoaderProxy.class) {
        [AFBrowserViewController.loaderProxy loadVideo:videoUrl completion:completion];
    } else {
        completion(videoUrl);
    }
}

@end
