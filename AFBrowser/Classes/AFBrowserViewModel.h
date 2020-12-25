//
//  AFBrowserViewModel.h
//  AFBrowser
//
//  Created by alfie on 2020/12/25.
//
//  浏览器ViewModel

#import <Foundation/Foundation.h>
#import "AFBrowserItem.h"

@interface AFBrowserViewModel : NSObject

+ (instancetype)viewModelWithItem:(AFBrowserItem *)item;


/** AFBrowserItem */
@property (nonatomic, strong) AFBrowserItem     *item;

/** 是否自动播放视频，默认NO */
@property (assign, nonatomic) BOOL              autoPlay;

/** 播放视频时，是否显示控制条，默认不显示 */
@property (assign, nonatomic) BOOL              showVideoControl;

/** 当前视频播放进度时间 */
@property (nonatomic, assign) NSTimeInterval    currentTime;


/**
 * @brief 返回已下载的视频或图片的本地地址
 */
- (NSString *)filePath;

/**
 * @brief 返回content是否有值
 */
- (BOOL)validContent;

/**
 * @brief 返回content是否是有效的远程url
 */
- (BOOL)validRemoteUrl;


@end


