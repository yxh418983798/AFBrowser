//
//  AFDownloader.h
//  AFBrowser
//
//  Created by alfie on 2020/9/10.
//
//  下载类

#import <Foundation/Foundation.h>

@interface AFDownloader : NSObject

typedef void(^AFDownloaderCompletion)(NSString *url, NSError *error);
typedef void(^AFDownloaderProgress)(NSProgress *progress);


/**
 * @brief 下载视频
 *
 * @param url 视频的url地址
 * @param completion 下载完成的回调
 */
+ (void)downloadVideo:(NSString *)url progress:(AFDownloaderProgress)progress completion:(AFDownloaderCompletion)completion;

+ (void)cancelTask:(NSString *)url;


/// 完成下载的路径
+ (NSString *)filePathWithUrl:(NSString *)url;

@end


