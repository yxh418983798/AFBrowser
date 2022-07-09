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

@class AFPlayerView, AFBrowserVideoItem, AFBrowserConfiguration;

@protocol AFPlayerViewDelegate <NSObject>

/// 更新状态
- (void)playerView:(AFPlayerView *)playerView updatePlayerStatus:(AFPlayerStatus)status;

/// 更新播放进度
- (void)playerView:(AFPlayerView *)playerView updateProgressWithCurrentTime:(float)currentTime durationTime:(float)durationTime animated:(BOOL)animated;

/// 播放结束，区别于Stop
- (void)playFinishOnPlayerView:(AFPlayerView *)playerView;

/// 点击Player的回调
- (void)tapActionOnPlayerView:(AFPlayerView *)playerView;

/// dismissPlayer的回调
- (void)dismissActionOnPlayerView:(AFPlayerView *)playerView;

/// 当player不可播放时，点击的回调，一般用于外部的提示
- (void)tapActionOnDisablePlayerView:(AFPlayerView *)playerView;

@end


@interface AFPlayerView : UIView

/** 控制所有播放器，设置为false则会暂停所有播放器，必须设置回true，否则调用play也不会播放 */
@property (class) BOOL  enable;

/** 视频数据源 */
@property (nonatomic, strong) AFBrowserVideoItem  *item;

/** 播放器状态 */
@property (nonatomic, assign) AFPlayerStatus      status;

/** 代理 */
@property (weak, nonatomic) id <AFPlayerViewDelegate> delegate;

/** 代理 */
@property (weak, nonatomic) id <AFPlayerViewDelegate> browserDelegate;

/** 底部工具栏 */
@property (strong, nonatomic) AFPlayerBottomBar   *bottomBar;

/** 记录toolBar的显示状态 */
@property (assign, nonatomic) BOOL                showVideoControl;

/** 是否静音 */
@property (nonatomic, assign) BOOL                muted;

/** AFBrowserConfiguration */
@property (nonatomic, weak) AFBrowserConfiguration *configuration;

/** 填充模式 */
@property (nonatomic, strong) AVLayerVideoGravity  videoGravity;


@property (nonatomic, assign) AFPlayerResumeOption          resumeOption;


/// 构造方法，share：是否使用单例播放器，默认true
+ (instancetype)playerViewWithSharePlayer:(BOOL)share;

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
+ (AFPlayerView *)playerWithItem:(AFBrowserVideoItem *)item configuration:(AFBrowserConfiguration *)configuration;

/**
 * @brief 准备播放
 *
 * @discussion
 * 会触发预下载
 * 下载完成后如果播放器不是单例，则会触发视频解码
 * 如果播放器是单例，只会解码当前播放器的视频数据
 */
- (void)prepare;

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

+ (AFPlayerView *)cachePlayerWithItem:(AFBrowserVideoItem *)item;

@end



