//
//  AFBrowserItem.h
//  MostOne
//
//  Created by alfie on 2019/11/5.
//  Copyright © 2019 MostOne. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AFPlayer;

/// 数据类型
typedef NS_ENUM(NSUInteger, AFBrowserItemType) {
    AFBrowserItemTypeImage,  /// 图片
    AFBrowserItemTypeVideo,  /// 视频
};

/// 加载图片的状态
typedef NS_ENUM(NSUInteger, AFLoadImageStatus) {
    AFLoadImageStatusNone,      /// 无图片
    AFLoadImageStatusCover,     /// 已加载 缩略、封面图片
    AFLoadImageStatusOriginal,  /// 已加载原始高清图片
};


@interface AFBrowserItem : NSObject

/** 类型 */
@property (assign, nonatomic) AFBrowserItemType type;

/** content */
@property (strong, nonatomic) id                content;

/** 缩略图/封面图 */
@property (strong, nonatomic) id                coverImage;

/** 视频时长 */
@property (assign, nonatomic) float             duration;

/** 宽度 */
@property (nonatomic, assign) CGFloat           width;

/** 高度 */
@property (nonatomic, assign) CGFloat           height;

/** 是否自动播放视频，默认NO */
@property (assign, nonatomic) BOOL              autoPlay;

/** 视频转场时，是否使用外部播放器进行转场动画，如果为YES，则视频播放是连续的（前提条件是外部有提供播放器），默认NO */
@property (assign, nonatomic) BOOL              useCustomPlayer;

/** 播放视频时，是否显示控制条，默认不显示 */
@property (assign, nonatomic) BOOL              showVideoControl;

/** 播放视频时，是否无限循环播放 */
@property (assign, nonatomic) BOOL              infiniteLoop;

/** player */
@property (nonatomic, weak) AFPlayer            *player;

/**
 * @brief 返回已下载的视频或图片的本地地址
 */
- (NSString *)filePath;


/**
 * @brief 构造图片数据
 *
 * @param image       图片数据，支持UIImage，NSString的url，NSURL）
 * @param coverImage  缩略图，可空，支持UIImage，NSString的url，NSURL）
 * @param width       图片宽度，可空
 * @param height      图片高度，可空
 */
+ (instancetype)itemWithImage:(id)image coverImage:(id)coverImage width:(CGFloat)width height:(CGFloat)height;


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


