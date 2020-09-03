//
//  AFPlayer.h
//  AFModule
//
//  Created by alfie on 2020/3/9.
//
//  简洁版 视频播放器，基于AVPlayer封装

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "AFPlayerBottomBar.h"

@class AFPlayer;
@protocol AFPlayerDelegate <NSObject>

/**
 * 播放器准备完成，进入可播放状态，建议在这里进行play
 */
- (void)prepareDoneWithPlayer:(AFPlayer *)player;

/**
 * 播放结束，区别于Stop
 */
- (void)finishWithPlayer:(AFPlayer *)player;

@end


@interface AFPlayer : UIView

/** 代理 */
@property (weak, nonatomic) id <AFPlayerDelegate> delegate;

/** 封面图 */
@property (strong, nonatomic) id                  coverImage;

/** 底部工具栏 */
@property (strong, nonatomic) AFPlayerBottomBar   *bottomBar;

/** 记录toolBar的显示状态 */
@property (assign, nonatomic) BOOL                showToolBar;

/**
 * 准备播放
 *
 * @param url       播放地址
 * @param duration  视频时长，如果传0，则自动获取，会有延迟
 */
- (void)prepareWithURL:(NSURL *)url duration:(float)duration;


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



