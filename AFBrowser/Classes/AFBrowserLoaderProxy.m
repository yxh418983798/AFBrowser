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
#import <objc/runtime.h>
#import <YYImage/YYImage.h>

@interface AFBrowserLoaderProxy ()

/** 执行方法 */
@property (assign, nonatomic) SEL                selector;

@property (nonatomic, weak) id target;

@end


@implementation AFBrowserLoaderProxy

#pragma mark - 判断图片是否在缓存中
+ (UIImage *)imageFromCacheForKey:(NSString *)key {
    if ([AFBrowserViewController.loaderProxy respondsToSelector:@selector(imageFromCacheForKey:)]) {
        return [AFBrowserViewController.loaderProxy imageFromCacheForKey:key];
    } else {
        return [SDImageCache.sharedImageCache imageFromCacheForKey:key];
    }
}


#pragma mark - 加载图片，默认使用SD
+ (void)loadImage:(NSURL *)imageUrl completion:(void (^)(UIImage *, NSError *))completion {
    if ([AFBrowserViewController.loaderProxy respondsToSelector:@selector(loadImage:completion:)]) {
        [AFBrowserViewController.loaderProxy loadImage:imageUrl completion:completion];
    } else {

        [SDWebImageManager.sharedManager loadImageWithURL:imageUrl options:SDWebImageRetryFailed progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
            NSString *url = imageURL.absoluteString;
            NSData *imageData = [SDImageCache.sharedImageCache diskImageDataForKey:url];
            if ([self isGIFData:imageData]) {
                YYImage *gifImage = [YYImage imageWithData:imageData];
                if (gifImage) {
                    completion(gifImage, error);
                    return;
                }
            }
            completion(image, error);
        }];
    }
}


+ (BOOL)isGIFData:(NSData *)data {
    if (data.length < 16) return NO;
    UInt32 magic = *(UInt32 *)data.bytes;
    if ((magic & 0xFFFFFF) != '\0FIG') return NO;
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFTypeRef)data, NULL);
    if (!source) return NO;
    size_t count = CGImageSourceGetCount(source);
    CFRelease(source);
    return count > 1;
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



+ (instancetype)aVPlayerItemDidPlayToEndTimeNotificationWithTarget:(id)target selector:(SEL)selector {
    AFBrowserLoaderProxy *proxy = AFBrowserLoaderProxy.new;
    proxy.target = target;
    proxy.selector = selector;
    [NSNotificationCenter.defaultCenter addObserver:proxy selector:@selector(finishedPlayAction:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    return proxy;
}

- (void)finishedPlayAction:(NSNotification *)notification {
    if (self.target) {
        [self.target performSelector:@selector(finishedPlayAction:) withObject:notification];
    } else {
        [NSNotificationCenter.defaultCenter removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    }
}


+ (void)addLogString:(NSString *)log {
#ifdef DEBUG
    if ([AFBrowserViewController.loaderProxy respondsToSelector:@selector(addLogString:)]) {
        [AFBrowserViewController.loaderProxy addLogString:log];
    }
#endif
}

- (void)dealloc {
    NSLog(@"-------------------------- Proxy释放了 --------------------------");
}


@end
