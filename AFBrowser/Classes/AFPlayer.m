//
//  AFPlayer.m
//  AFModule
//
//  Created by alfie on 2020/3/9.
//

#import "AFPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import "AFBrowserViewController.h"
#import "AFBrowserLoaderProxy.h"
#import "AFBrowserItem.h"
#import "AFBrowserConfiguration.h"
#import <objc/runtime.h>

static int const AFDownloadBlockCode = 6666;

@implementation AFPlayerProxy

@end

@interface AFPlayer ()

/** AFPlayerProxy */
@property (nonatomic, strong) AFPlayerProxy     *proxy;

/** 父视图 */
@property (nonatomic, strong) UIView            *superView;

/** 播放器 */
@property (nonatomic, strong) AVPlayer          *player;

/** playerLayer */
@property (nonatomic, strong) AVPlayerLayer     *playerLayer;

/** 记录playerItem */
@property (nonatomic, strong) AVPlayerItem      *playerItem;

/** 记录是否在监听 */
@property (nonatomic, assign) BOOL          isObserving;

/** 监听进度对象 */
@property (strong, nonatomic) id            playerObserver;

/** isFirstFrame */
@property (nonatomic, assign) BOOL          didFirstFrame;

@end


static NSString * const AFPlayerNotificationPauseAllPlayer = @"AFPlayerNotificationPauseAllPlayer";
static NSString * const AFPlayerNotificationResumeAllPlayer = @"AFPlayerNotificationResumeAllPlayer";
static AFPlayerPauseAllReason _PauseAllReason = AFPlayerPauseAllReasonNone; // 记录播放器全局状态
static int playerCount = 0;

@implementation AFPlayer

#pragma mark - 构造方法
/// 单例
+ (instancetype)sharePlayer {
    static AFPlayer *player;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        player = AFPlayer.new;
    });
    return player;
}

- (instancetype)init {
    if (self = [super init]) {
        self.proxy = AFPlayerProxy.new;
        self.proxy.target = self;
        playerCount ++;
        NSLog(@"-------------------------- 创建播放器:%d ,%@--------------------------", playerCount, self);
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(pauseAllPlayerNotification) name:AFPlayerNotificationPauseAllPlayer object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(resumeAllPlayerNotification) name:AFPlayerNotificationResumeAllPlayer object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(finishedPlayAction:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationDidReceiveMemoryWarningNotification) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}


#pragma mark - 生命周期
- (void)applicationDidReceiveMemoryWarningNotification {
    NSLog(@"-------------------------- 收到内存警告:%@ --------------------------", self.item);
}
 
- (void)layout {
    [CATransaction begin];
    [CATransaction setAnimationDuration:0];
    [CATransaction setDisableActions:YES];
    self.playerLayer.frame = self.playerFrame;
    [CATransaction commit];
}

- (void)dealloc {
    playerCount--;
    NSLog(@"-------------------------- %d播放器释放：%@ --------------------------", playerCount, self);
    [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"[dealloc]播放器释放了, %@", self.displayDescription]];
    [self replacePlayerItem:nil];
    [_playerLayer removeFromSuperlayer];
    _player = nil;
    _playerLayer = nil;
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

/// 释放
- (void)destroy {
    NSLog(@"-------------------------- destroyAFplayer --------------------------");
    if (!NSThread.isMainThread) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_player) [_player pause];
            [_player replaceCurrentItemWithPlayerItem:nil];
            if (_playerLayer.superlayer) [_playerLayer removeFromSuperlayer];
            _player = nil;
            _playerLayer = nil;
        });
    } else {
        if (_player) [_player pause];
        [self removeKVO];
        [_player replaceCurrentItemWithPlayerItem:nil];
        if (_playerLayer.superlayer) [_playerLayer removeFromSuperlayer];
        _player = nil;
        _playerLayer = nil;
    }
//    [NSNotificationCenter.defaultCenter removeObserver:self];
}


- (NSString *)displayDescription {
    return nil;
//    return [NSString stringWithFormat:@"播放器描述：%p\n url:%@\n item.content:%@, status:%d, hidden:%d\nProgress：%g, \ncover:%@, \nduration:%g, width:%g, height:%g\ncurrentItem:%@\n showVideoControl:%d", self,  self.url, self.item.content, self.status, self.hidden, self.item.progress, self.item.coverImage, self.duration, self.item.width, self.item.height, _player.currentItem, self.showVideoControl];
}


// 控制器即将销毁，做一些转场动画的处理
- (void)browserWillDismiss {
    self.showVideoControl = NO;
//    self.transitionStatus = AFPlayerTransitionStatusTransitioning;
//    [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"willDismiss转场隐藏Toolbar, %@", self.displayDescription]];
}

/// 控制器已经Dismiss，做一些转场动画的处理
- (void)browserDidDismiss {
    self.showVideoControl = NO;
//    self.transitionStatus = AFPlayerTransitionStatusSmall;
//    [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"didDismiss转场隐藏Toolbar, %@", self.displayDescription]];
}

/// 控制器取消Dismiss，做一些恢复处理
- (void)browserCancelDismiss {
    if (self.isPlay) {
        [self startPlay];
    }
//    self.showVideoControl = self.item.showVideoControl;
//    self.transitionStatus = AFPlayerTransitionStatusFullScreen;
//    [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"取消转场恢复Toolbar, %@", self.displayDescription]];
}


- (void)resetPlayer {
    [_playerLayer removeFromSuperlayer];
    _playerLayer = nil;
    [self replacePlayerItem:nil];
}


#pragma mark - setter
//- (void)setItem:(AFBrowserItem *)item {
//    _item.currentTime = self.item.progress * self.item.duration;
//    if (!_item || ![_item isEqual:item]) {
//        _item = item;
////        [self.player replaceCurrentItemWithPlayerItem:nil];
//        [self replacePlayerItem:nil];
//        if (_item.showVideoControl && _bottomBar.superview) [self addSubview:self.bottomBar];
//        [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"设置item: %@", self.displayDescription]];
//    } else {
//        _item = item;
//    }
//}

- (void)setConfiguration:(AFBrowserConfiguration *)configuration {
    _configuration = configuration;
    if (_configuration.muteOption == AFPlayerMuteOptionNever) {
        self.player.muted = NO;
    } else if (_configuration.muteOption == AFPlayerMuteOptionAlways) {
        self.player.muted = YES;
    }
}

- (void)setMuted:(BOOL)muted {
    _muted = muted;
    self.player.muted = muted;
}

- (void)setVideoGravity:(AVLayerVideoGravity)videoGravity {
    _videoGravity = videoGravity;
    if (self.item.videoContentScale == 0) {
        _playerLayer.videoGravity = videoGravity;
    }
}


#pragma mark - Getter
- (BOOL)isReadyForDisplay {
    return self.playerLayer.isReadyForDisplay;
}

/// 播放器
- (AVPlayer *)player {
    if (!_player) {
        _player = [AVPlayer playerWithPlayerItem:nil];
        _player.usesExternalPlaybackWhileExternalScreenIsActive = YES;
        if (@available(iOS 10.0, *)) {
            _player.automaticallyWaitsToMinimizeStalling = NO;
        }
        _player.muted = self.muted;
    }
    return _player;
}

/// 播放器layer
- (AVPlayerLayer *)playerLayer {
    if (!_playerLayer) {
        _playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
//        _playerLayer.videoGravity = AVLayerVideoGravityResize;
//        _playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        _playerLayer.videoGravity = self.configuration.videoGravity;
        _playerLayer.masksToBounds= YES;
    }
    return _playerLayer;
}

/// 时长
- (float)duration {
    if (self.player.currentItem) {
        float time = CMTimeGetSeconds(self.player.currentItem.duration);
        return time > 0 ? time : self.item.duration;
    }
    return self.item.duration;
}

/// 获取播放器frame
- (CGRect)playerFrame {
    if (self.item.videoContentScale > 0) {
        CGFloat height = fmin(self.superView.frame.size.width/self.item.videoContentScale, self.superView.frame.size.height);
        return CGRectMake(0, (self.superView.frame.size.height - height)/2, self.superView.frame.size.width, height);
    }
    CGSize size = self.player.currentItem.presentationSize;
    if (size.width == 0) size.width = self.item.width;
    if (size.height == 0) size.height = self.item.height;
    if (self.playerLayer.videoGravity == AVLayerVideoGravityResizeAspect && size.width > 0 && size.height > 0) {
        CGFloat height = fmin(self.superView.frame.size.width * size.height/size.width, self.superView.frame.size.height);
        return CGRectMake(0, (self.superView.frame.size.height - height)/2, self.superView.frame.size.width, height);
    } else {
        return self.superView.bounds;
    }
}

/// 是否正在播放
- (BOOL)isPlay {
    return self.item.playerStatus == AFPlayerStatusPlay || self.item.playerStatus == AFPlayerStatusLoading;
}


#pragma mark - 更新UI
/// 根据状态，更新UI
- (void)updatePlayerStatus:(AFPlayerStatus)status {
    [self.item updatePlayerStatus:status];
    if ([self.delegate respondsToSelector:@selector(player:updatePlayerStatus:)]) {
        [self.delegate player:self updatePlayerStatus:status];
    }
}

/// 跳转
- (void)seekToTime:(NSTimeInterval)time {
    [self.player seekToTime:CMTimeMakeWithSeconds(time, self.player.currentItem.asset.duration.timescale) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    self.item.currentTime = time;
}

/// 更新bottomBar的进度
- (void)updateProgressWithCurrentTime:(float)currentTime durationTime:(float)durationTime animated:(BOOL)animated {
    if ([self.delegate respondsToSelector:@selector(player:updateProgressWithCurrentTime:durationTime:animated:)]) {
        [self.delegate player:self updateProgressWithCurrentTime:currentTime durationTime:durationTime animated:animated];
    }
}


#pragma mark - 数据
/// 切换PlayerItem
- (void)replacePlayerItem:(AVPlayerItem *)item {
    
    if (item && item == self.player.currentItem) {
        NSLog(@"-------------------------- 错误！!! --------------------------");
        return;
    }
    self.playerItem = item;
    if (self.player.currentItem) {
        [self.player pause];
//        NSLog(@"-------------------------- 移除111 --------------------------");
        [self removeKVO];
        [self.player replaceCurrentItemWithPlayerItem:nil];
        if (item) {
//            NSLog(@"-------------------------- 添加KVO 111 --------------------------");
            [self addKVOWithItem:item];
        }
    } else {
        if (item) {
//            NSLog(@"-------------------------- 移除KVO 222--------------------------");
            [self removeKVO];
//            NSLog(@"-------------------------- 添加KVO 222--------------------------");
            [self addKVOWithItem:item];
        }
    }
}

/// 首帧回调
- (void)onFirstFrame {
    if (self.item.playerStatus == AFPlayerStatusPlay) return;
    // 播放结束的时候也会走进onFirstFrame，此时需要过滤结束的状态，通过rate==0来判断
    if (self.player.rate == 0) return;
    if (self.playerLayer.isReadyForDisplay) {
        if (self.player.currentItem.status != AVPlayerItemStatusReadyToPlay) {
            NSLog(@"-------------------------- 首帧回调错误:%f --------------------------", self.player.rate);
        }
        NSLog(@"-------------------------- 首帧回调成功:%f --------------------------", self.player.rate);
        [self updatePlayerStatus:(AFPlayerStatusPlay)];
    } else {
        NSLog(@"-------------------------- 首帧回调，播放器未准备好:%f --------------------------", self.player.rate);
    }
}

/// item变化，更新播放器设置
- (void)onUpdateItem {
    // 填充模式
    if (self.item.videoContentScale > 0) {
        self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    } else {
        self.playerLayer.videoGravity = self.item.videoGravity;
    }
    // 静音设置
    switch (self.item.muteOption) {
        case AFPlayerMuteOptionNever:
            self.player.muted = NO;
            break;
            
        case AFPlayerMuteOptionAlways:
            self.player.muted = YES;
            break;
            
        case AFPlayerMuteOptionAlwaysButBrowser:
            if ([AFBrowserConfiguration.currentVc isKindOfClass:NSClassFromString(@"AFBrowserViewController")]) {
                self.player.muted = NO;
            } else {
                self.player.muted = YES;
            }
            break;
        default:
            break;
    }
}


#pragma mark - 下载
/// 预加载
+ (void)preloadingItem:(AFBrowserVideoItem *)item {
    [AFBrowserLoaderProxy preloadingVideo:item.content];
}

/// 开始下载
- (void)downloadItem:(AFBrowserVideoItem *)item {
    __weak typeof(self) weakSelf = self;
    NSString *urlString = item.content;
    AFBrowserVideoItem *loadingItem = item;
    [AFBrowserLoaderProxy loadVideo:urlString progress:nil completion:^(NSString *url, NSError *error) {
        if (error) {
            [weakSelf onLoadFailed:loadingItem error:error block:error.code == AFDownloadBlockCode];
        } else {
            [weakSelf onLoadSuccess:loadingItem];
        }
    }];
}

/// 下载失败处理
- (void)onLoadFailed:(AFBrowserVideoItem *)loadingItem error:(NSError *)error block:(BOOL)block {
    
    [loadingItem updateItemStatus:AFBrowserVideoItemStatusFailed];
    if (loadingItem == self.item) {
        AFPlayerStatus status = block ? AFPlayerStatusBlock : AFPlayerStatusFailed;
        [self updatePlayerStatus:status];
        [self completionError:error];
    } else {
        AFPlayerStatus status = block ? AFPlayerStatusBlock : AFPlayerStatusNormal;
        [self updatePlayerStatus:status];
    }
    if ([self.configuration.delegate respondsToSelector:@selector(browser:loadVideoFailed:error:)]) {
        [self.configuration.delegate browser:self.configuration.browserVc loadVideoFailed:self.item error:error];
    }
}

/// 下载成功处理
- (void)onLoadSuccess:(AFBrowserVideoItem *)loadingItem {
    if (loadingItem == self.item && loadingItem.playerStatus == AFPlayerStatusLoading) {
        // 下载成功，解码播放
        [self preparePlayer];
    } else {
        // 已切换item，更新状态为下载完成
        [loadingItem updateItemStatus:AFBrowserVideoItemStatusLoaded];
        [loadingItem updatePlayerStatus:AFPlayerStatusNormal];
    }
}


#pragma mark - 解码
/// 播放器准备
- (void)preparePlayer {
    NSLog(@"-------------------------- 开始解码 :%@ --------------------------", self.superView);
    AFBrowserVideoItem *selectedItem = self.item;
    [selectedItem updateItemStatus:AFBrowserVideoItemStatusPrepare];
    [selectedItem updatePlayerStatus:AFPlayerStatusLoading];
    NSString *path = self.item.localPath;
    NSError *error;
    if (!path.length) {
        error = [NSError errorWithDomain:@"AFPlayer" code:80400 userInfo:@{@"error" : @"播放视频错误：path为空"}];
        [self prepareDoneWithError:error selectedItem:selectedItem];
        return ;
    }
    // 播放器
    [self replacePlayerItem:self.item.playerItem];
    NSLog(@"-------------------------- 解码状态：%d %d --------------------------", self.player.status, self.player.currentItem.status);
}

/// 解码
- (void)prepareItem {
    __weak typeof(self) weakSelf = self;
    AFBrowserItem *item = self.item;
    [self.player prerollAtRate:1 completionHandler:^(BOOL finished) {
        if (!finished) {
            NSLog(@"-------------------------- AFPlayer 解码finished：%d -- %@--------------------------", finished, item.content);
        }
        [weakSelf prepareDoneWithError:nil selectedItem:item];
    }];
}

/// 解码完成回调
- (void)prepareDoneWithError:(NSError *)error selectedItem:(AFBrowserVideoItem *)selectedItem {
    // 解码失败
    if (error) {
        //                NSError *error = [NSError errorWithDomain:path code:80401 userInfo:@{@"msg" : @"解码失败"}];
        NSLog(@"-------------------------- 解码失败：%@ -- %@ --------------------------", error, selectedItem.content);
        [selectedItem updateItemStatus:AFBrowserVideoItemStatusFailed];
        [self updatePlayerStatus:AFPlayerStatusFailed];
        [self completionError:error];
        return;
    }
    // 解码成功，开始播放
    if (selectedItem == self.item) {
        if (selectedItem.playerStatus == AFPlayerStatusLoading) {
            NSLog(@"-------------------------- 解码完成，准备播放：%@ -- %@ --------------------------", self.superView, selectedItem.content);
            [selectedItem updateItemStatus:AFBrowserVideoItemStatusPrepareDone];
            [self play:NO];
        } else {
            NSLog(@"-------------------------- 解码完成，但状态不对：%@ -- %@ --------------------------", self.superView, selectedItem.content);
        }
    } else {
        NSLog(@"-------------------------- 解码完成，但Item已切换：%@ -- %@ --------------------------", self.superView, selectedItem.content);
    }
    if ([self.delegate respondsToSelector:@selector(prepareDoneWithPlayer:)]) {
        [self.delegate prepareDoneWithPlayer:self];
    }
}


#pragma mark - 播放
/// 播放视频
- (void)playVideoItem:(AFBrowserVideoItem *)item superview:(UIView *)superview completion:(void (^)(NSError *))completion {
    item.pauseReason = AFPlayerPauseAllReasonNone;
    self.completion = completion;
    // 停止当前item
    if (self.item != item) {
        NSLog(@"-------------------------- 切换Item，old:%@ -- new:%@ --------------------------", [self.superView performSelector:@selector(displayDescription)], [superview performSelector:@selector(displayDescription)]);
        if (self.item) {
            [self stop];
        }
        self.item = item;
        [self onUpdateItem];
    }
    // 父视图为空
    if (!superview) {
        [self completionError:[NSError errorWithDomain:@"AFPlayer" code:80400 userInfo:@{@"error" : @"播放视频错误：superview为空"}]];
        return;
    }
    // 更新父视图
    if (self.superView != superview) {
        NSLog(@"-------------------------- 切换superview，old:%@ -- new:%@ --------------------------", [self.superView performSelector:@selector(displayDescription)], [superview performSelector:@selector(displayDescription)]);
        // 可能出现Item复用的情况，此时item不变，但父视图变了，需要在这里再调用一次stop
        if (self.item.playerStatus != AFPlayerStatusNormal) {
            [self stop];
        }
        self.delegate = superview;
        self.superView = superview;
        [self.superView.layer insertSublayer:self.playerLayer atIndex:0];
        [self layout];
    }
    // content为空
    if (!item.content) {
        [self updatePlayerStatus:(AFPlayerStatusFailed)];
        [self completionError:[NSError errorWithDomain:@"AFPlayer" code:80400 userInfo:@{@"error" : @"播放视频错误：item.content为空"}]];
        return;
    }
    // 判断是否下载完成
    if (item.localPath.length) {
        // 已完成下载，判断Item的数据状态
        switch (item.itemStatus) {
                // 解码中，则直接忽略
            case AFBrowserVideoItemStatusPrepare:
                NSLog(@"-------------------------- 忽略解码中：%@ --------------------------", self.superView);
                break;
                
                // 解码完成，可直接播放
            case AFBrowserVideoItemStatusPrepareDone: {
                [self play:NO];
            }
                break;
                
                // 其他状态，开始解码
            default: {
                [self preparePlayer];
            }
                break;
        }
        
    } else {
        // 未完成下载，开启下载任务并提高下载优先级
        [self.item updateItemStatus:AFBrowserVideoItemStatusLoading];
        [self updatePlayerStatus:AFPlayerStatusLoading];
        [self downloadItem:self.item];
    }
}

/// 播放
- (void)play:(BOOL)isRetry {
    // item为空
    if (!self.item.content) {
        [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"[play]播放错误content为空, %@", self.displayDescription]];
        [self updatePlayerStatus:(AFPlayerStatusFailed)];
        [self completionError:[NSError errorWithDomain:@"AFPlayer" code:80400 userInfo:@{@"error" : @"播放视频错误：item.content为空"}]];
        return;
    }
    // playerItem为空
    if (!self.player.currentItem) {
        [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"[play]播放错误playerItem为空, %@", self.displayDescription]];
        [self playVideoItem:self.item superview:self.superView completion:self.completion];
        [self completionError:[NSError errorWithDomain:@"AFPlayer" code:80400 userInfo:@{@"error" : @"播放视频错误：player.currentItem为空"}]];
        return;
    }
    // 切换item
    if (self.configuration && self.configuration.transitionStyle != AFBrowserTransitionStyleContinuousVideo && self.configuration.currentItem != self.item) {
        [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"[play]播放错误，已经切换到其他Item, %@", self.displayDescription]];
        [self stop];
        return;
    }
    if ([AFBrowserViewController.loaderProxy respondsToSelector:@selector(shouldPlayVideo:playerView:)]) {
        // 代理控制
        if (![AFBrowserViewController.loaderProxy shouldPlayVideo:self.item playerView:self.superView]) {
            [self pause];
            return;
        }
    } else {
        // 开关控制
        if (_PauseAllReason) {
            [self pause];
            NSLog(@"-------------------------- 播放过滤，关闭全局播放器 --------------------------");
            return;
        }
    }
    // 状态不对，重新开始播放流程
    if (self.player.currentItem.status != AVPlayerItemStatusReadyToPlay) {
        [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"[play]播放状态错误, playerItem.status = %d", self.player.currentItem.status]];
        [self.item updateItemStatus:(AFBrowserVideoItemStatusDefault)];
        [self playVideoItem:self.item superview:self.superView completion:self.completion];
        return;
    }
    // 检查playerLayer状态
    if (!self.playerLayer.isReadyForDisplay) {
        [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"[play]playerLayer状态错误"]];
        if (isRetry) {
            [self updatePlayerStatus:(AFPlayerStatusFailed)];
            return;
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self play:YES];
        });
        return;
    }
    // 如果已播放完毕，进度重置到起始位置
    if (self.item.progress >= 1) {
        [self seekToTime:0.f];
        [self updateProgressWithCurrentTime:0 durationTime:self.duration animated:NO];
    }
    // 开始播放
    [self startPlay];
}

/// 开始播放，更新UI
- (void)startPlay {
    NSLog(@"-------------------------- startPlay：%@ --------------------------", self.superView);
    [self layout];
    self.item.pauseReason = AFPlayerPauseAllReasonNone;
    [self.item updateItemStatus:AFBrowserVideoItemStatusPrepareDone];
    if ([self.configuration.delegate respondsToSelector:@selector(browser:willPlayVideoItem:)]) {
        [self.configuration.delegate browser:[self.browserDelegate performSelector:@selector(delegate)] willPlayVideoItem:self.item];
    }
    [self.player play];
    if (_showVideoControl) {
        self.bottomBar.playBtn.selected = YES;
    }
}


#pragma mark - 暂停
/// 暂停
- (void)pause {
    [self pausePlay];
}

/// 暂停
- (void)pausePlay {
    self.item.pauseReason = AFPlayerPauseAllReasonNone;
    self.item.currentTime = self.item.progress * self.duration;
    [self updatePlayerStatus:(AFPlayerStatusNormal)];
//    if (self.item.itemStatus > AFBrowserVideoItemStatusLoaded) {
//        self.item.itemStatus = AFBrowserVideoItemStatusLoaded;
//    }
    [self.player pause];
}


#pragma mark - 停止
- (void)stop {
    self.item.progress = 0;
    self.item.currentTime = 0;
    [self replacePlayerItem:nil];
    if (self.item.itemStatus > AFBrowserVideoItemStatusLoaded) {
        self.item.itemStatus = AFBrowserVideoItemStatusLoaded;
    }
    [self updatePlayerStatus:AFPlayerStatusNormal];
}


#pragma mark - 播放结束
- (void)finishedPlay {
    self.item.progress = 0;
    [self seekToTime:0.f];
    if (!self.item.loop) {
        [self pause];
        [self completionError:nil];
    } else {
        [self startPlay];
    }
}


#pragma mark - 错误回调
- (void)completionError:(NSError *)error {
    if (self.completion) {
        self.completion(error);
    }
}


#pragma mark - KVO
/// 添加观察者
- (void)addKVOWithItem:(AVPlayerItem *)item {
    [item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [self.player replaceCurrentItemWithPlayerItem:item];
    // 如果已经是准备完成状态了，这里需要调用statusDidChange
    if (item.status == AVPlayerItemStatusReadyToPlay) {
        [self statusDidChange];
    }
    
    self.isObserving = YES;
    if (!self.playerObserver) {
        __weak typeof(self) weakSelf = self;
        self.playerObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(0.05, NSEC_PER_SEC) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
            // 视频第一次回调
            weakSelf.item.progress = CMTimeGetSeconds(time) / weakSelf.duration;
            if (isnan(weakSelf.item.progress) || weakSelf.item.progress > 1.0) {
                weakSelf.item.progress = 0.f;
                weakSelf.item.currentTime = 0;
//                NSLog(@"-------------------------- 进度回调异常:%f --------------------------", self.player.rate);
            } else {
                [weakSelf onFirstFrame];
                weakSelf.item.currentTime = CMTimeGetSeconds(time);
            }
            [weakSelf updateProgressWithCurrentTime:CMTimeGetSeconds(time) durationTime:weakSelf.duration animated:YES];
        }];
    } else {
        NSLog(@"-------------------------- 添加KVO错误 --------------------------");
    }
}

/// 移除观察者
- (void)removeKVO {
    @try {
        [_player.currentItem removeObserver:self forKeyPath:@"status"];
        [_player removeTimeObserver:self.playerObserver];
    } @catch (NSException *exception) {
        if (self.isObserving || self.playerObserver) {
            [AFBrowserLoaderProxy addLogString:@"KVO异常"];
        }
    }
    self.isObserving = NO;
    self.playerObserver = nil;
}

/// 监听回调
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"status"]) {
        [self statusDidChange];
    }
}

/// 状态改变
- (void)statusDidChange {
    __weak typeof(self) weakSelf = self;
    switch (self.player.currentItem.status) {
            // 播放器准备完成
        case AVPlayerItemStatusReadyToPlay:
            [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"播放器准备完成 ,%@", self.displayDescription]];
            // 解码
            if (self.item.itemStatus == AFBrowserVideoItemStatusPrepare) {
                [self prepareItem];
            }
            break;
            // 播放器准备失败
        case AVPlayerItemStatusFailed:
            [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"播放器准备错误 ,%@\n %@", self.player.error, self.displayDescription]];
            if (self.item.itemStatus == AFBrowserVideoItemStatusPrepare) {
                NSError *error = self.player.error ?: [NSError errorWithDomain:@"AFPlayer" code:80401 userInfo:@{@"msg" : @"解码失败"}];
                [self prepareDoneWithError:error selectedItem:self.item];
            }
            break;
            
        default:
            NSLog(@"-------------------------- 无法识别的状态 --------------------------");
            break;
    }
}


#pragma mark - 通知
/// 收到通知：播放器 播放结束
- (void)finishedPlayAction:(NSNotification *)notification {
    if (notification.object != self.player.currentItem) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(finishWithPlayer:)]) {
        [self.delegate finishWithPlayer:self];
    }
    [self finishedPlay];
}

/// 获取全局播放器暂停原因
+ (AFPlayerPauseAllReason)pauseAllReason {
    return _PauseAllReason;
}

/// 收到通知：暂停所有正在播放的播放器
+ (void)pauseAllPlayer:(AFPlayerPauseAllReason)reason {
    _PauseAllReason = reason;
    NSLog(@"-------------------------- 暂停所有播放器 --------------------------");
    [NSNotificationCenter.defaultCenter postNotificationName:AFPlayerNotificationPauseAllPlayer object:nil];
}
- (void)pauseAllPlayerNotification {
    if (self.isPlay) {
        // 代理控制
        if ([AFBrowserViewController.loaderProxy respondsToSelector:@selector(shouldPauseVideo:playerView:)]) {
            if (![AFBrowserViewController.loaderProxy shouldPauseVideo:self.item playerView:self.superView]) {
                return ;
            }
        }
        [self pausePlay];
        self.item.pauseReason = _PauseAllReason;
    }
}

/// 收到通知：恢复所有播放器的状态，如果暂停前是正在播放的，会继续播放
+ (void)resumeAllPlayer {
    _PauseAllReason = AFPlayerPauseAllReasonNone;
    NSLog(@"-------------------------- 恢复所有播放器 --------------------------");
    [NSNotificationCenter.defaultCenter postNotificationName:AFPlayerNotificationResumeAllPlayer object:nil];
}
- (void)resumeAllPlayerNotification {

    if (self.item.playerStatus == AFPlayerStatusNormal && self.item.pauseReason) {
        if (self.shouldResume) {
            [self playVideoItem:self.item superview:self.superView completion:self.completion];
            self.resumeOption = AFPlayerResumeOptionNone;
        }
    }
}

/// 是否恢复
- (BOOL)shouldResume {
    // 代理控制
    if ([AFBrowserViewController.loaderProxy respondsToSelector:@selector(shouldResumeVideo:playerView:)]) {
        if (![AFBrowserViewController.loaderProxy shouldResumeVideo:self.item playerView:self.superView]) {
            return NO;
        }
    }
    if (self.resumeOption != AFPlayerResumeOptionBrowserAppeared) return YES;
    if ([AFBrowserConfiguration.currentVc isKindOfClass:NSClassFromString(@"AFBrowserViewController")]) return YES;
    return NO;
}

/// Target被释放的通知
- (void)playerControllerProxyDeallocNotification:(NSNotification *)notification {
    NSLog(@"-------------------------- 收到Proxy释放通知：%@ --------------------------", notification.object);
    [self destroy];
}


#pragma mark - 播放器数组管理
/// 保存当前所有的播放器
+ (NSMutableDictionary <NSString *, AFPlayer *> *)currentPlayers {
    static NSMutableDictionary *players;
    if (!players) {
        players = NSMutableDictionary.dictionary;
    }
    return players;
}

//+ (AFPlayer *)addPlayer:(AFPlayer *)player {
//
//}




@end





