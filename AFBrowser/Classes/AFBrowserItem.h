//
//  AFBrowserItem.h
//  MostOne
//
//  Created by alfie on 2019/11/5.
//  Copyright © 2019 MostOne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFBrowserEnum.h"

@interface AFBrowserItem : NSObject

/** 类型 */
@property (assign, nonatomic) AFBrowserItemType type;

/** content */
@property (strong, nonatomic) id                content;

/** 缩略图/封面图 */
@property (strong, nonatomic) id                coverImage;

/** 宽度 */
@property (nonatomic, assign) CGFloat           width;

/** 高度 */
@property (nonatomic, assign) CGFloat           height;

/** 空间大小 */
@property (nonatomic, assign) CGFloat           size;

/** 视频时长 */
@property (assign, nonatomic) float             duration;

/** 是否自动播放视频，默认NO */
@property (assign, nonatomic) BOOL              autoPlay;

/** 播放视频时，是否显示控制条，默认不显示 */
@property (assign, nonatomic) BOOL              showVideoControl;

/** 当前视频播放进度时间 */
@property (nonatomic, assign) NSTimeInterval    currentTime;

/** userInfo，自定义参数 */
@property (strong, nonatomic) id                userInfo;


/**
 * @brief 返回已下载的视频或图片的本地地址
 */
- (NSString *)filePath;


/**
 * @brief 返回content是否有值
 */
- (BOOL)validContent;


- (BOOL)validRemoteUrl;


/**
 * @brief 构造图片数据
 *
 * @param image       图片数据，支持UIImage，NSString的url，NSURL）
 * @param coverImage  缩略图，可空，支持UIImage，NSString的url，NSURL）
 * @param width       图片宽度，可空
 * @param height      图片高度，可空
 * @param size        图片空间大小，可空，单位B
 */
+ (instancetype)itemWithImage:(id)image coverImage:(id)coverImage width:(CGFloat)width height:(CGFloat)height size:(CGFloat)size;


/**
 * @brief 构造视频数据
 *
 * @param video       视频数据（支持NSString的url、URL）
 * @param coverImage  封面图，可空，支持UIImage，NSString的url，NSURL）
 * @param duration    视频时长，如果传0，则自动获取，会有延迟
 * @param width       视频宽度，可空
 * @param height      视频高度，可空
 */
+ (instancetype)itemWithVideo:(id)video coverImage:(id)coverImage duration:(CGFloat)duration width:(CGFloat)width height:(CGFloat)height;



@end


