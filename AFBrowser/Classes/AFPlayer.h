//
//  AFPlayer.h
//  AFModule
//
//  Created by alfie on 2020/3/9.
//
//  视频播放器，基于AVPlayer封装

#import <AVFoundation/AVFoundation.h>
#import "AFPlayerBottomBar.h"
#import "AFBrowserEnum.h"


@class AFPlayer, AFBrowserVideoItem, AFBrowserConfiguration;

@protocol AFPlayerDelegate <NSObject>

/// 更新状态
- (void)player:(AFPlayer *)player updatePlayerStatus:(AFPlayerStatus)status;

/// 更新播放进度
- (void)player:(AFPlayer *)player updateProgressWithCurrentTime:(float)currentTime durationTime:(float)durationTime animated:(BOOL)animated;

/// 播放器准备完成，进入可播放状态，建议在这里进行play
- (void)prepareDoneWithPlayer:(AFPlayer *)player;

/// 播放结束，区别于Stop
- (void)finishWithPlayer:(AFPlayer *)player;

/// 点击Player的回调
- (void)tapActionInPlayer:(AFPlayer *)player;

/// dismissPlayer的回调
- (void)dismissActionInPlayer:(AFPlayer *)player;

/// 当player不可播放时，点击的回调，一般用于外部的提示
- (void)tapActionInDisablePlayer:(AFPlayer *)player;

@end



@interface AFPlayer : NSObject

/** 控制所有播放器，设置为false则会暂停所有播放器，必须设置回true，否则调用play也不会播放 */
@property (class) BOOL  enable;

/** 代理 */
@property (weak, nonatomic) id <AFPlayerDelegate> delegate;

/** 代理 */
@property (weak, nonatomic) id <AFPlayerDelegate> browserDelegate;

/** 视频数据源 */
@property (nonatomic, strong) AFBrowserVideoItem  *item;

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

/// 播放器layer
- (AVPlayerLayer *)playerLayer;

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
- (void)playVideoItem:(AFBrowserVideoItem *)item superview:(UIView *)superview completion:(void(^)(NSError *error))completion;

/*!
 * @brief 暂停视频
 */
- (void)pause;

/*!
 * @brief 停止视频
 */
- (void)stop;

/// 跳转进度
- (void)seekToTime:(NSTimeInterval)time;

/// 更新布局
- (void)layout;

/// 播放器是否已准备完成
- (BOOL)isReadyForDisplay;

/// 时长
- (float)duration;

/// 预加载
+ (void)preloadingItem:(AFBrowserVideoItem *)item;

/// 开始下载
- (void)downloadItem:(AFBrowserVideoItem *)item;

/// 销毁播放器
- (void)destroy;

/// 是否在拖拽进度
- (BOOL)isSliderTouch;

/// 返回转场动画使用的size
- (CGSize)transitionSize;

/// 暂停所有正在播放的播放器
+ (void)pauseAllPlayer;

/// 恢复所有播放器的状态，如果暂停前是正在播放的，会继续播放
+ (void)resumeAllPlayer;


@end



@interface AFPlayerProxy : NSObject

/** 播放器 */
@property (nonatomic, weak) id            target;

@end

