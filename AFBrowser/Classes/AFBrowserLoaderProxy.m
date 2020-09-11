//
//  AFBrowserLoaderProxy.m
//  AFBrowser
//
//  Created by alfie on 2020/9/2.
//

#import "AFBrowserLoaderProxy.h"
#import "UIImageView+WebCache.h"
#import "SDImageCache.h"
#import "AFDownloader.h"
#import "AFBrowserViewController.h"


@implementation AFBrowserLoaderProxy

#pragma mark - 判断图片是否在缓存中
+ (BOOL)hasImageCacheWithKey:(NSString *)key {
    if ([AFBrowserViewController.loaderProxy respondsToSelector:@selector(hasImageCacheWithKey:)]) {
        return [AFBrowserViewController.loaderProxy hasImageCacheWithKey:key];
    } else {
        return [SDImageCache.sharedImageCache diskImageDataExistsWithKey:key];
    }
}


#pragma mark - 加载图片，默认使用SD
+ (void)loadImage:(NSURL *)imageUrl completion:(void (^)(UIImage *, NSError *))completion {
    if ([AFBrowserViewController.loaderProxy respondsToSelector:@selector(loadImage:completion:)]) {
        [AFBrowserViewController.loaderProxy loadImage:imageUrl completion:completion];
    } else {
        [SDWebImageManager.sharedManager loadImageWithURL:imageUrl options:kNilOptions progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
            completion(image, error);
        }];
    }
}


#pragma mark - 加载视频
+ (void)loadVideo:(NSString *)videoUrl progress:(void (^)(NSProgress *))progress completion:(void (^)(NSString *, NSError *))completion {
    if ([AFBrowserViewController.loaderProxy respondsToSelector:@selector(loadVideo:completion:)]) {
        [AFBrowserViewController.loaderProxy loadVideo:videoUrl progress:progress completion:completion];
    } else {
        if ([videoUrl containsString:@"https://"] || [videoUrl containsString:@"http://"]) {
            [AFDownloader downloadVideo:videoUrl progress:progress completion:^(NSString *url, NSError *error) {
                completion([NSString stringWithFormat:@"file://%@", url], error);
            }];
        } else {
            completion(videoUrl, nil);
        }
    }
}






@end
