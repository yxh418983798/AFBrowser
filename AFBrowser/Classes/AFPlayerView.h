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

/** 播放器唯一Id，可用于控制播放器 */
@property (nonatomic, assign) int64_t             playerId;

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

/// 当前视频Item
- (AFBrowserVideoItem *)item;

/// 构造方法，share：是否使用单例播放器，默认true
+ (instancetype)playerViewWithSharePlayer:(BOOL)share;

/**
 * @brief 准备播放
 *
 * @param item 视频数据
 * @param active 是否将当前的播放器设置为活跃状态
 *
 * @discussion
 * 通常情况一个播放器对应一个playerId
 * 如果出现多个播放器对应一个playerId的情况，则缓存池中只会有一个活跃的播放器
 * 通过类方法对播放器进行的操作都需要播放器处于活跃状态
 */
- (void)prepareVideoItem:(AFBrowserVideoItem *)item active:(BOOL)active;

/*!
 * @brief 播放视频
 *
 * @param item 视频数据
 * @param completion 播放结束回调
 *
 * @discussion
 * 会自动将当前播放器设置为活跃状态
 * 如果item未下载完成，AFPlayer会自动加入下载任务并优先下载当前的item
 * 下载期间如果用户未切换或暂停、停止播放item，则AFPlayer在下载完成后会自动播放
 */
- (void)playVideoItem:(AFBrowserVideoItem *)item completion:(void(^)(NSError *error))completion;

/// 暂停播放
- (void)pause;

/// 停止播放
- (void)stop;

/// 跳转到指定进度
- (void)seekToTime:(NSTimeInterval)time;

/// 通过playerId获取播放器，返回当前活跃的播放器
+ (AFPlayerView *)getPlayerView:(int64_t)playerId;

/// 播放指定playerId的播放器（播放器需要处于活跃状态）
+ (AFPlayerView *)playPlayer:(int64_t)playerId;

/// 暂停指定的播放器（播放器需要处于活跃状态）
+ (AFPlayerView *)pausePlayer:(int64_t)playerId;

/// 停止指定的播放器（播放器需要处于活跃状态）
+ (AFPlayerView *)stopPlayer:(int64_t)playerId;

/// 获取当前是否有播放器在播放
+ (BOOL)isPlaying;

/// 暂停单例播放器
+ (void)pauseSharePlayer;

/// 停止单例播放器
+ (void)stopSharePlayer;

/// 获取全局播放器暂停原因
+ (AFPlayerPauseAllReason)pauseAllReason;

/// 暂停所有正在播放的播放器
+ (void)pauseAllPlayer:(AFPlayerPauseAllReason)reason;

/// 恢复所有播放器的状态，如果暂停前是正在播放的，会继续播放
+ (void)resumeAllPlayer;



/// 返回转场动画使用的size
- (CGSize)transitionSize;

/// 控制器即将Dismiss，做一些转场动画的处理
- (void)browserWillDismiss;

/// 控制器已经Dismiss，做一些转场动画的处理
- (void)browserDidDismiss;

/// 控制器取消Dismiss，做一些恢复处理
- (void)browserCancelDismiss;

- (void)destroy;

- (BOOL)isSliderTouch;




@end



