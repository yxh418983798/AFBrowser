//
//  AFPlayer.h
//  AFModule
//
//  Created by alfie on 2020/3/9.
//
//  视频播放器，基于AVPlayer封装

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "AFPlayerBottomBar.h"
#import "AFBrowserItem.h"

@class AFPlayer;
@protocol AFPlayerDelegate <NSObject>

/// 播放器准备完成，进入可播放状态，建议在这里进行play
- (void)prepareDoneWithPlayer:(AFPlayer *)player;

/// 播放结束，区别于Stop
- (void)finishWithPlayer:(AFPlayer *)player;

/// 点击Player的回调
- (void)tapActionInPlayer:(AFPlayer *)player;


@end


@interface AFPlayer : UIView

/** 代理 */
@property (weak, nonatomic) id <AFPlayerDelegate> delegate;

/** 底部工具栏 */
@property (strong, nonatomic) AFPlayerBottomBar   *bottomBar;

/** 记录toolBar的显示状态 */
@property (assign, nonatomic) BOOL                showToolBar;

/** 是否静音 */
@property (nonatomic, assign) BOOL                muted;

/** AFBrowserItem */
@property (nonatomic, strong) AFBrowserItem       *item;

- (CGSize)transitionSize;

/**
 * 准备播放
 */
- (void)prepare;

- (void)releasePlayer;

/**
 * 播放视频
 */
- (void)play;


/**
 * 暂停视频
 */
- (void)pause;


/**
 * 停止视频
 */
- (void)stop;


/**
 * 跳转进度
 */
- (void)seekToTime:(NSTimeInterval)time;


/**
 * 控制器即将Dismiss，做一些转场动画的处理
 */
- (void)browserWillDismiss;


/**
 * 控制器取消Dismiss，做一些恢复处理
 */
- (void)browserCancelDismiss;

@end



