//
//  AFDownloader.m
//  AFBrowser
//
//  Created by alfie on 2020/9/10.
//

#import "AFDownloader.h"
#include <CommonCrypto/CommonCrypto.h>
#import "AFBrowserViewController.h"

@interface AFDownloader () <NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

/** 下载任务 */
@property (nonatomic, strong) NSURLSessionDownloadTask *task;

/** 下载数据 */
@property (nonatomic, strong) NSData                   *resumeData;

/** session */
@property (nonatomic, strong) NSURLSession             *session;

/** url */
@property (nonatomic, copy) NSString                   *url;

/** 完成回调 */
@property (nonatomic, copy) AFDownloaderCompletion     completion;

/** 进度回调 */
@property (nonatomic, copy) AFDownloaderProgress       progress;

@end


@implementation AFDownloader

#pragma mark - 生命周期
- (void)dealloc {
    NSLog(@"-------------------------- AFDownloader释放：%@ --------------------------", self.url);
}


#pragma mark - 配置
+ (NSURLSessionConfiguration *)defaultURLSessionConfiguration {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.HTTPShouldSetCookies = YES;
    configuration.HTTPShouldUsePipelining = NO;
    configuration.requestCachePolicy = NSURLRequestUseProtocolCachePolicy;
    configuration.allowsCellularAccess = YES;
    configuration.timeoutIntervalForRequest = 60.0;
//    configuration.URLCache = self.defaultURLCache;
    return configuration;
}

+ (NSURLCache *)defaultURLCache {
    if ([[[UIDevice currentDevice] systemVersion] compare:@"8.2" options:NSNumericSearch] == NSOrderedAscending) return [NSURLCache sharedURLCache];
    return [[NSURLCache alloc] initWithMemoryCapacity:20 * 1024 * 1024 diskCapacity:150 * 1024 * 1024 diskPath:@"com.Alfie.downloader"];
}

/// 返回url的MD5字符串
+ (NSString *)md5String:(NSString *)string {
    if (!string.length) return nil;
    NSData *data = [string dataUsingEncoding:(NSUTF8StringEncoding)];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(data.bytes, (CC_LONG)data.length, result);
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

- (NSURLSession *)session {
    if (!_session) {
        _session = [NSURLSession sessionWithConfiguration:AFDownloader.defaultURLSessionConfiguration delegate:self delegateQueue:NSOperationQueue.mainQueue];
    }
    return _session;
}

/// 获取本地视频的地址
+ (NSString *)videoPathWithUrl:(NSString *)url {
    if (!url.length) return nil;
    if ([AFBrowserViewController.loaderProxy respondsToSelector:@selector(filePathWithVideoUrl:)]) {
        NSString *path = [AFBrowserViewController.loaderProxy filePathWithVideoUrl:url];
        if (path.length) return path;
    }
    NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *filePath = [NSString stringWithFormat:@"%@/af-download/video/%@.mp4", cachesPath, [self md5String:url]];
    return [NSFileManager.defaultManager fileExistsAtPath:filePath] ? filePath : nil;
}

/// 完成下载的路径
+ (NSString *)filePathWithUrl:(NSString *)url {
    if ([AFBrowserViewController.loaderProxy respondsToSelector:@selector(filePathWithVideoUrl:)]) {
        NSString *path = [AFBrowserViewController.loaderProxy filePathWithVideoUrl:url];
        if (path.length) return path;
    }
    NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *filePath = [NSString stringWithFormat:@"%@/af-download/video", cachesPath];
    if (![NSFileManager.defaultManager fileExistsAtPath:filePath]) {
        [NSFileManager.defaultManager createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return [filePath stringByAppendingFormat:@"/%@.mp4", [self md5String:url]];
}

/// 未完成下载的路径
+ (NSString *)resumeFilePathWithUrl:(NSString *)url {
    NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *filePath = [NSString stringWithFormat:@"%@/af-download/resumeVideo", cachesPath];
    if (![NSFileManager.defaultManager fileExistsAtPath:filePath]) {
        [NSFileManager.defaultManager createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return [filePath stringByAppendingFormat:@"/%@", [self md5String:url]];
}


#pragma mark - 存储容器
static NSMutableDictionary *_downloadTasks;
/// 懒加载
+ (NSMutableDictionary *)downloadTasks {
    if (!_downloadTasks) {
        _downloadTasks =  NSMutableDictionary.dictionary;
    }
    return _downloadTasks;
}

/// 查询
+ (AFDownloader *)downloaderForKey:(NSString *)key {
    if (!key) return nil;
    return [self.downloadTasks valueForKey:key];
}

/// 删除
+ (void)addDownloader:(AFDownloader *)downloader forKey:(NSString *)key {
    if (![self.downloadTasks.allKeys containsObject:key] && key.length) {
        [self.downloadTasks setValue:downloader forKey:key];
    }
}

/// 删除
+ (void)removeDownloader:(NSString *)key {
    if ([self.downloadTasks.allKeys containsObject:key]) {
        [self.downloadTasks removeObjectForKey:key];
    }
}


#pragma mark - 下载视频
+ (void)downloadVideo:(NSString *)url progress:(AFDownloaderProgress)progress completion:(AFDownloaderCompletion)completion {
    
    // 如果本地中已经存在视频，直接返回
    NSString *filePath = [self filePathWithUrl:url];
    if([NSFileManager.defaultManager fileExistsAtPath:filePath]) {
//        NSLog(@"-------------------------- 本地存在视频：%@ --------------------------", filePath);
        if (completion) {
            completion(filePath, nil);
        }
        return;
    }
    
    // 如果本地中有未完成的下载，继续下载
    filePath = [self resumeFilePathWithUrl:url];
    if([NSFileManager.defaultManager fileExistsAtPath:filePath]) {
//        NSLog(@"-------------------------- 恢复本地下载：%@ --------------------------", filePath);
        [self resumeTask:url completion:completion];
        return;
    }
    
    // 如果正在下载任务，忽略此次操作
    if ([self.downloadTasks.allKeys containsObject:url]) return;
    
    // 发起新的下载任务
    AFDownloader *downloader = AFDownloader.new;
    [downloader startTask:url resumeData:nil completion:completion];
}


#pragma mark - 开始下载任务
- (void)startTask:(NSString *)url resumeData:(NSData *)resumeData completion:(AFDownloaderCompletion)completion {
    self.url = url;
    self.completion = completion;
    if (resumeData) {
        self.task = [self.session downloadTaskWithResumeData:self.resumeData];
    } else {
        self.task = [self.session downloadTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
        [self.task resume];
    }
    [AFDownloader addDownloader:self forKey:url];
}


#pragma mark - 取消/暂停任务
+ (void)cancelTask:(NSString *)url {
    AFDownloader *downloader = [self downloaderForKey:url];
    if (!downloader) return;
    __weak typeof(self) weakSelf = self;
    [downloader.task cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
        NSLog(@"-------------------------- 取消任务：%@ --------------------------", NSThread.currentThread);
        if (resumeData) {
            /// 将数据临时写入本地
            [downloader.resumeData writeToFile:[weakSelf resumeFilePathWithUrl:url] atomically:YES];
        }
        [weakSelf removeDownloader:url];
    }];
}


#pragma mark - 恢复下载任务
+ (void)resumeTask:(NSString *)url completion:(AFDownloaderCompletion)completion {
    NSString *filePath = [self resumeFilePathWithUrl:url];
    NSData *resumeData = [NSData dataWithContentsOfFile:filePath];
    AFDownloader *downloader = [self downloaderForKey:url];
    if (!downloader) {
        downloader = AFDownloader.new;
        [self addDownloader:downloader forKey:url];
    }
    [downloader startTask:url resumeData:resumeData completion:completion];
}


#pragma mark NSURLSessionDelegate
/* 主线程执行；更新进度值
 * bytesWritten:每次服务器返回的数据大小
 * totalBytesWritten:截止到目前为止，下载数据大小
 * totalBytesExpectedToWrite:下载的总数据的大小(bytes)
 */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {

    // 下载进度
    CGFloat progress = totalBytesWritten / (double)totalBytesExpectedToWrite;
    dispatch_async(dispatch_get_main_queue(), ^{
//        NSLog(@"服务器当前返回的数据大小:%lld; 进度值:%f; 线程:%@", bytesWritten, progress, [NSThread currentThread]);
    });
}

/// 下载完毕
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {

    NSString *filePath = [AFDownloader filePathWithUrl:self.url];
//    NSLog(@"-------------------------- 下载完成：%@  -- %@ --------------------------", location, filePath);
    // 移动文件到指定的路径
    if(![NSFileManager.defaultManager fileExistsAtPath:filePath]) {
        NSError *error;
        [NSFileManager.defaultManager moveItemAtURL:location toURL:[NSURL fileURLWithPath:filePath] error:&error];
        if (self.completion) {
            self.completion(filePath, error);
        }
    } else {
        if (self.completion) {
            self.completion(filePath, nil);
        }
    }
}

@end
