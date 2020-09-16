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


/**
 * @brief 取消下载
 *
 * @param url 视频的url地址
 */
+ (void)cancelTask:(NSString *)url;


/**
 * @brief 获取本地视频的地址，如果不存在，返回空
 *
 * @param url 视频的url地址
 */
+ (NSString *)videoPathWithUrl:(NSString *)url;


/**
 * @brief 返回完成下载的本地路径
 *
 * @param url 视频的url地址
 */
+ (NSString *)filePathWithUrl:(NSString *)url;

@end


