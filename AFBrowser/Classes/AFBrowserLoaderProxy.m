//
//  AFBrowserLoaderProxy.m
//  AFBrowser
//
//  Created by alfie on 2020/9/2.
//

#import "AFBrowserLoaderProxy.h"
#import "UIImageView+WebCache.h"
#import "SDImageCache.h"
#import "SDWebImageDownloader.h"
#import "AFBrowserViewController.h"

@interface AFBrowserLoaderProxy () <NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (strong, nonatomic, nonnull) NSOperationQueue *downloadQueue;
//@property (strong, nonatomic, nonnull) NSMutableDictionary<NSURL *, NSOperation<SDWebImageDownloaderOperation> *> *URLOperations;
//@property (strong, nonatomic, nullable) NSMutableDictionary<NSString *, NSString *> *HTTPHeaders;
//@property (strong, nonatomic, nonnull) dispatch_semaphore_t HTTPHeadersLock; // A lock to keep the access to `HTTPHeaders` thread-safe
//@property (strong, nonatomic, nonnull) dispatch_semaphore_t operationsLock; // A lock to keep the access to `URLOperations` thread-safe

// The session in which data tasks will run
@property (strong, nonatomic) NSURLSession *session;

@end


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
+ (void)loadImage:(NSURL *)imageUrl completion:(void (^)(UIImage *))completion {
    if ([AFBrowserViewController.loaderProxy respondsToSelector:@selector(loadImage:completion:)]) {
        [AFBrowserViewController.loaderProxy loadImage:imageUrl completion:completion];
    } else {
        [SDWebImageManager.sharedManager loadImageWithURL:imageUrl options:kNilOptions progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
            completion(image);
        }];
    }
}


#pragma mark - 加载视频，暂未处理
+ (void)loadVideo:(NSURL *)videoUrl completion:(void (^)(NSURL *))completion {
    if ([AFBrowserViewController.loaderProxy respondsToSelector:@selector(loadVideo:completion:)]) {
        [AFBrowserViewController.loaderProxy loadVideo:videoUrl completion:completion];
    } else {
//        NSURLSession *session = [[NSURLSession alloc] init];
//        [session downloadTaskWithURL:videoUrl completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
//            NSLog(@"-------------------------- 加载完成了：error:%@  location:%@, response:%@ --------------------------", error, location, response);
//        }];
//        [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:[NSURL URLWithString:model.lnk] options:SDWebImageDownloaderLowPriority progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
//            //            UIImage *image = [manager imageWithLocalPath:[manager imagePathWithFileKey:model.fileKey] andNetUrl:model.receiveMsg isDown:YES];
//            UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
//        }];
        
        completion(videoUrl);
    }
}


//
//#pragma mark NSURLSessionDataDelegate
//
//- (void)URLSession:(NSURLSession *)session
//          dataTask:(NSURLSessionDataTask *)dataTask
//didReceiveResponse:(NSURLResponse *)response
// completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
//
//    // Identify the operation that runs this task and pass it the delegate method
//    NSOperation<SDWebImageDownloaderOperation> *dataOperation = [self operationWithTask:dataTask];
//    if ([dataOperation respondsToSelector:@selector(URLSession:dataTask:didReceiveResponse:completionHandler:)]) {
//        [dataOperation URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
//    } else {
//        if (completionHandler) {
//            completionHandler(NSURLSessionResponseAllow);
//        }
//    }
//}
//
//- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
//
//    // Identify the operation that runs this task and pass it the delegate method
//    NSOperation<SDWebImageDownloaderOperation> *dataOperation = [self operationWithTask:dataTask];
//    if ([dataOperation respondsToSelector:@selector(URLSession:dataTask:didReceiveData:)]) {
//        [dataOperation URLSession:session dataTask:dataTask didReceiveData:data];
//    }
//}
//
//- (void)URLSession:(NSURLSession *)session
//          dataTask:(NSURLSessionDataTask *)dataTask
// willCacheResponse:(NSCachedURLResponse *)proposedResponse
// completionHandler:(void (^)(NSCachedURLResponse *cachedResponse))completionHandler {
//
//    // Identify the operation that runs this task and pass it the delegate method
//    NSOperation<SDWebImageDownloaderOperation> *dataOperation = [self operationWithTask:dataTask];
//    if ([dataOperation respondsToSelector:@selector(URLSession:dataTask:willCacheResponse:completionHandler:)]) {
//        [dataOperation URLSession:session dataTask:dataTask willCacheResponse:proposedResponse completionHandler:completionHandler];
//    } else {
//        if (completionHandler) {
//            completionHandler(proposedResponse);
//        }
//    }
//}






@end
