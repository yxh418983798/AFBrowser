//
//  AFBrowserItem.h
//  MostOne
//
//  Created by alfie on 2019/11/5.
//  Copyright © 2019 MostOne. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "AFBrowserEnum.h"

@class AVPlayerItem;

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

/** userInfo，自定义参数 */
@property (strong, nonatomic) id                userInfo;

/** presentedTrasitionView的原始frame */
@property (assign, nonatomic) CGRect          presentedTrasitionViewFrame;

/** 记录trasitionView的原始frame */
@property (assign, nonatomic) CGRect          trasitionViewOriginalFrame;

/** 图片转场，记录开始转场的frame，用于转场后意外情况的恢复 */
@property (assign, nonatomic) CGRect          imageBeginTransitionFrame;

/** 记录转场View的present前的frame */
@property (assign, nonatomic) CGRect          frameBeforePresent;

/** 记录转场view的dismiss前的frame */
@property (assign, nonatomic) CGRect          frameBeforeDismiss;

/** 浏览器imageView的高度 */
@property (assign, nonatomic) CGFloat         imgView_H;

/** 浏览器imageView的高度 */
@property (assign, nonatomic) CGFloat         progress;

/** 记录tag */
@property (nonatomic, assign) NSInteger       originalTag;

/** 视频时长 */
@property (assign, nonatomic) float             duration;

/** 是否自动播放视频，默认NO */
@property (assign, nonatomic) BOOL              autoPlay;

/** 播放视频时，是否显示控制条，默认不显示 */
@property (assign, nonatomic) BOOL              showVideoControl;

/** 当前视频播放进度时间 */
@property (nonatomic, assign) NSTimeInterval    currentTime;


- (BOOL)isEqualToItem:(AFBrowserItem *)item;

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
+ (__kindof AFBrowserItem *)itemWithVideo:(id)video coverImage:(id)coverImage duration:(CGFloat)duration width:(CGFloat)width height:(CGFloat)height;


/**
 * @brief 构造自定义视图
 */
+ (__kindof AFBrowserItem *)itemWithCustomView:(UIView *)view;

@end


#pragma mark - 视频Item
@interface AFBrowserVideoItem : AFBrowserItem

/** 视频下载完成的本地路径，如果未下载完成，则返回nil */
@property (nonatomic, copy) NSString            *localPath;

/** playerItem */
@property (nonatomic, strong) AVPlayerItem      *playerItem;

/** 播放器的填充方式，默认AVLayerVideoGravityResizeAspectFill完全填充 */
@property (nonatomic, copy) AVLayerVideoGravity videoGravity;

/** 使用固定的比例填充（宽:高），默认为0，使用videoGravity填充，videoContentScale不为0时videoGravity会无效 */
@property (nonatomic, assign) CGFloat           videoContentScale;

/** 封面图的填充方式，默认自动根据videoGravity来适应 */
@property (nonatomic, assign)  UIViewContentMode coverContentMode;

/** 是否无限循环播放，默认NO */
@property (nonatomic, assign) BOOL              loop;

/** 静音播放控制 */
@property (nonatomic, assign) AFPlayerMuteOption        muteOption;

/** 播放视频时，是否显示控制条，默认NO */
@property (assign, nonatomic) BOOL                      videoControlEnable;

/** 暂停播放视频时，是否显示播放按钮，默认YES */
@property (assign, nonatomic) BOOL                      playBtnEnable;

/** 数据状态 */
@property (nonatomic, assign) AFBrowserVideoItemStatus  itemStatus;

/** 播放器状态 */
@property (nonatomic, assign) AFPlayerStatus            playerStatus;

/** 暂停原因 */
@property (nonatomic, assign) AFPlayerPauseReason       pauseReason;
  


/// 更新状态
- (void)updatePlayerStatus:(AFPlayerStatus)status;
- (void)updateItemStatus:(AFBrowserVideoItemStatus)itemStatus;


@end


#pragma mark - 自定义Item
@interface AFBrowserCustomItem : AFBrowserItem

/** view */
@property (nonatomic, strong) UIView            *view;


@end
