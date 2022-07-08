//
//  AFPlayerView.h
//  AFBrowser
//
//  Created by alfie on 2022/7/8.
//
//  视频播放器，基于AVPlayer封装

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "AFPlayerBottomBar.h"
#import "AFBrowserEnum.h"
#import "AFPlayer.h"

@class AFPlayerView, AFBrowserVideoItem, AFBrowserConfiguration;


@interface AFPlayerView : UIView

/** 播放器，默认使用单例，如果想支持多个视频同时播放，则需要重新构造AFPlayer，playerView.player = AFPlayer.new */
@property (nonatomic, strong) AFPlayer            *player;

/** 视频数据源 */
@property (nonatomic, strong) AFBrowserVideoItem  *item;

/** 播放器状态 */
@property (nonatomic, assign) AFPlayerStatus      status;

/** 代理 */
@property (weak, nonatomic) id <AFPlayerDelegate> delegate;

/** 代理 */
@property (weak, nonatomic) id <AFPlayerDelegate> browserDelegate;

/** 底部工具栏 */
@property (strong, nonatomic) AFPlayerBottomBar   *bottomBar;

/** 记录toolBar的显示状态 */
@property (assign, nonatomic) BOOL                showVideoControl;

/** 是否静音 */
@property (nonatomic, assign) BOOL                muted;

/** AFBrowserConfiguration */
@property (nonatomic, weak) AFBrowserConfiguration *configuration;

@property(copy) AVLayerVideoGravity videoGravity;

@property (class) int          maxPlayer;


@property (nonatomic, assign) AFPlayerResumeOption          resumeOption;


/// 单例
+ (instancetype)sharePlayer;

/*!
 * @brief 播放视频
 *
 * @param item 视频数据
 * @param completion 播放结束回调
 *
 * @discussion
 * 如果item未下载完成，AFPlayer会自动加入下载任务并优先下载当前的item
 * 下载期间如果用户未切换或暂停、停止播放item，则AFPlayer在下载完成后会自动播放
 */
- (void)playVideoItem:(AFBrowserVideoItem *)item completion:(void(^)(NSError *error))completion;



/**
 * @brief 构造播放器
 */
+ (AFPlayer *)playerWithItem:(AFBrowserVideoItem *)item configuration:(AFBrowserConfiguration *)configuration;


/**
 * @brief 准备播放
 */
- (void)prepare;

/**
 * @brief 播放视频
 */
- (void)play;

/**
 * @brief 暂停视频
 */
- (void)pause;

/**
 * @brief 停止视频
 */
- (void)stop;

/**
 * @brief 跳转进度
 */
- (void)seekToTime:(NSTimeInterval)time;

- (void)destroy;

- (BOOL)isSliderTouch;


/// 返回转场动画使用的size
- (CGSize)transitionSize;

/// 控制器即将Dismiss，做一些转场动画的处理
- (void)browserWillDismiss;

/// 控制器已经Dismiss，做一些转场动画的处理
- (void)browserDidDismiss;

/// 控制器取消Dismiss，做一些恢复处理
- (void)browserCancelDismiss;

/// 暂停所有正在播放的播放器
+ (void)pauseAllPlayer;

/// 恢复所有播放器的状态，如果暂停前是正在播放的，会继续播放
+ (void)resumeAllPlayer;

+ (AFPlayer *)cachePlayerWithItem:(AFBrowserVideoItem *)item;

@end



