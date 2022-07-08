//
//  AFPlayerView.m
//  AFBrowser
//
//  Created by alfie on 2022/7/8.
//

#import "AFPlayerView.h"
#import <AVFoundation/AVFoundation.h>
#import "AFBrowserViewController.h"
#import "AFBrowserLoaderProxy.h"
#import "AFBrowserItem.h"
#import "AFBrowserConfiguration.h"
#import <objc/runtime.h>

static int const AFDownloadBlockCode = 6666;

@interface AFPlayerView ()

/** contentView */
@property (nonatomic, strong) UIView                  *contentView;

/** 播放器 */
@property (nonatomic, strong) AVPlayer                *player;

/** playerLayer */
@property (nonatomic, strong) AVPlayerLayer           *playerLayer;

/** 封面图 */
@property (strong, nonatomic) UIImageView             *coverImgView;

/** 中间的播放按钮 */
@property (strong, nonatomic) UIButton                *playBtn;

/** 左上角X按钮 */
@property (nonatomic, strong) UIButton                *dismissBtn;

/** 加载进度提示 */
@property (strong, nonatomic) UIActivityIndicatorView *activityView;

/** 播放的url */
@property (nonatomic, copy) NSString                  *url;

/** AFBrowserLoaderProxy */
@property (nonatomic, strong) AFBrowserLoaderProxy    *proxy;

/** 记录playerItem */
@property (nonatomic, strong) AVPlayerItem            *playerItem;

/** 准备完成后是否自动播放，默认No */
@property (assign, nonatomic) BOOL          playWhenPrepareDone;

/** 记录是否在监听 */
@property (nonatomic, assign) BOOL          isObserving;

/** 记录进度 */
@property (assign, nonatomic) CGFloat       progress;

/** 记录时长 */
//@property (assign, nonatomic) float         duration;

/** 监听进度对象 */
@property (strong, nonatomic) id            playerObserver;

/** proxy */
//@property (nonatomic, strong) AFPlayerProxy      *playerProxy;

/** isFirstFrame */
@property (nonatomic, assign) BOOL            didFirstFrame;

/** 播放回调 */
@property (nonatomic, copy) void (^completion)(NSError *error);

@end


static NSString * const AFPlayerNotificationPauseAllPlayer = @"AFPlayerNotificationPauseAllPlayer";
static NSString * const AFPlayerNotificationResumeAllPlayer = @"AFPlayerNotificationResumeAllPlayer";
static BOOL _AllPlayerSwitch = YES; // 记录播放器总开关
static int playerCount = 0;

@implementation AFPlayerView

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

+ (AFPlayer *)playerWithItem:(AFBrowserItem *)item configuration:(AFBrowserConfiguration *)configuration {
    AFPlayer *player = [[AFPlayer alloc] initWithFrame:(CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height))];
    player.item = item;
    player.configuration = configuration;
    return player;

//    AFPlayer *player;
//    if (configuration.transitionStyle == AFBrowserTransitionStyleContinuousVideo) {
//        player = [AFPlayerProxy cachePlayerWithItem:item];
//    } else {
//        player = [AFPlayer playerWithItem:item];
//    }
//    player.configuration = configuration;
//    if (configuration.muteOption == AFPlayerMuteOptionAlways) {
//        player.muted = YES;
//    }
//    return player;
}

+ (AFPlayer *)playerWithItem:(AFBrowserItem *)item {
    AFPlayer *player = [[AFPlayer alloc] initWithFrame:(CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height))];
    player.item = item;
    return player;
}


- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        playerCount ++;
        self.tag = playerCount;
        NSLog(@"-------------------------- 创建播放器:%d ,%@--------------------------", playerCount, self);
        [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"创建播放器, %@", self.displayDescription]];
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
    if (!self.superview ) {
        if (!_player) {
            self.coverImgView.image = nil;
        }
    }
}

- (void)didMoveToSuperview {
    self.clipsToBounds = YES;
//    self.frame = self.superview.bounds;
    [self.layer addSublayer:self.playerLayer];
    [self addSubview:self.contentView];
    [self.contentView addSubview:self.coverImgView];
    [self.coverImgView addSubview:self.activityView];
    [self.contentView addSubview:self.playBtn];
    if (self.item.showVideoControl) {
        [self.contentView addSubview:self.dismissBtn];
        [self addSubview:self.bottomBar];
    }
}

- (void)layoutSubviews {
    [CATransaction begin];
    [CATransaction setAnimationDuration:0];
    [CATransaction setDisableActions:YES];
    self.playerLayer.frame = self.playerFrame;
    [CATransaction commit];
    
    CGFloat size = 50.f;
    self.contentView.frame = self.bounds;
    self.coverImgView.frame = self.bounds;
    self.playBtn.frame = CGRectMake((self.frame.size.width - size)/2, (self.frame.size.height - size)/2, size, size);
    self.activityView.frame = CGRectMake((self.frame.size.width - size)/2, (self.frame.size.height - size)/2, size, size);
    if (self.item.showVideoControl) {
        self.dismissBtn.frame = CGRectMake(0, UIApplication.sharedApplication.statusBarFrame.size.height, 50, 44);
        self.bottomBar.frame = CGRectMake(0, self.frame.size.height - 80, self.frame.size.width, 50);
    }
    [super layoutSubviews];
}

- (void)dealloc {
    playerCount--;
    NSLog(@"-------------------------- %d播放器释放：%@ --------------------------", playerCount, self);
    [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"[dealloc]播放器释放了, %@", self.displayDescription]];
    [self replacePlayerItem:nil];
    [_playerLayer removeFromSuperlayer];
    _player = nil;
    _playerLayer = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self];
}


/// 释放
- (void)destroy {
    if (!NSThread.isMainThread) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_player) [_player pause];
            [self removeKVO];
            [_player replaceCurrentItemWithPlayerItem:nil];
            [_playerLayer removeFromSuperlayer];
            _player = nil;
            _playerLayer = nil;
            if (self.superview) [self removeFromSuperview];
        });
    } else {
        if (_player) [_player pause];
        [self removeKVO];
        [_player replaceCurrentItemWithPlayerItem:nil];
        [_playerLayer removeFromSuperlayer];
        _player = nil;
        _playerLayer = nil;
        if (self.superview) [self removeFromSuperview];
    }
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
//    [NSNotificationCenter.defaultCenter removeObserver:self];
    
//    id detector = [NSClassFromString(@"FBRetainCycleDetector") new];
//    [detector performSelector:@selector(addCandidate:) withObject:self];
//    NSSet *retainCycles = [detector performSelector:@selector(findRetainCycles)];
//    NSLog(@"---destory %@", retainCycles);
}


- (NSString *)displayDescription {
    return [NSString stringWithFormat:@"播放器描述：%p\n url:%@\n item.content:%@, status:%d, hidden:%d\nProgress：%g, \ncover:%@, \nduration:%g, width:%g, height:%g\ncurrentItem:%@\n showVideoControl:%d", self,  self.url, self.item.content, self.status, self.hidden, self.progress, self.item.coverImage, self.duration, self.item.width, self.item.height, _player.currentItem, self.showVideoControl];
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
- (void)setShowVideoControl:(BOOL)showVideoControl {
//    BOOL isFull = (self.frame.size.width == UIScreen.mainScreen.bounds.size.width) || (self.frame.size.height == UIScreen.mainScreen.bounds.size.height);
//    if ((!isFull || self.transitionStatus != AFPlayerTransitionStatusFullScreen) && showVideoControl) {
////        [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"异常Toolbar, %@", self.displayDescription]];
//        return;
//    }
    if (showVideoControl) {
        if (self.configuration.transitionStatus != AFTransitionStatusPresented) {
            return;
        }
//        NSLog(@"-------------------------- 显示控制条 --------------------------");
        self.dismissBtn.alpha = 1;
        self.bottomBar.alpha = 1;
        self.bottomBar.playBtn.selected = self.isPlay;
    } else {
        _bottomBar.alpha = 0;
        _dismissBtn.alpha = 0;
    }
    _showVideoControl = showVideoControl;
}

- (void)setItem:(AFBrowserItem *)item {
    _item.currentTime = self.item.progress * self.item.duration;
    if (!_item || ![_item isEqual:item]) {
        _item = item;
        _url = nil;
//        [self.player replaceCurrentItemWithPlayerItem:nil];
        [self replacePlayerItem:nil];
        if (_item.showVideoControl && _bottomBar.superview) [self addSubview:self.bottomBar];
        self.playWhenPrepareDone = NO;
        self.url = nil;
        _coverImgView.image = nil;
//        NSLog(@"-------------------------- 切换item，重置状态：%@ --------------------------", _item.content);
        [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"设置item: %@", self.displayDescription]];
    } else {
        _item = item;
    }
}

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

- (void)attachCoverImage:(id)image {
    __weak typeof(self) weakSelf = self;
    if ([self.item.coverImage isKindOfClass:NSString.class]) {
        UIImage *image = [AFBrowserLoaderProxy imageFromCacheForKey:self.item.coverImage];
        if (image) {
            self.coverImgView.image = image;
            return;
        }
        if (!self.coverImgView.image) {
            self.coverImgView.image = [self imageWithColor:UIColor.whiteColor];
        }
        [AFBrowserLoaderProxy loadImage:[NSURL URLWithString:(NSString *)self.item.coverImage] completion:^(UIImage *image, NSError *error) {
            weakSelf.coverImgView.image = image;
        }];
    } else if ([self.item.coverImage isKindOfClass:NSURL.class]) {
        UIImage *image = [AFBrowserLoaderProxy imageFromCacheForKey:[(NSURL *)self.item.coverImage absoluteString]];
        if (image) {
            self.coverImgView.image = image;
            return;
        }
        if (!self.coverImgView.image) {
            self.coverImgView.image = [self imageWithColor:UIColor.whiteColor];
        }
        [AFBrowserLoaderProxy loadImage:(NSURL *)self.item.coverImage completion:^(UIImage *image, NSError *error) {
            weakSelf.coverImgView.image = image;
        }];
    } else if ([self.item.coverImage isKindOfClass:UIImage.class]) {
        self.coverImgView.image = self.item.coverImage;
    } else if ([self.item.coverImage isKindOfClass:NSData.class]) {
        self.coverImgView.image = [UIImage imageWithData:self.item.coverImage];
    } else {
        self.coverImgView.image = [self imageWithColor:UIColor.whiteColor];
    }
}

- (void)setVideoGravity:(AVLayerVideoGravity)videoGravity {
    _videoGravity = videoGravity;
    _playerLayer.videoGravity = videoGravity;
}


#pragma mark - Getter
/// 获取空白时的封面图
- (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, self.item.width, self.item.height);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

/// 容器
- (UIView *)contentView {
    if (!_contentView) {
        _contentView = UIView.new;
        _contentView.backgroundColor = UIColor.clearColor;
        [_contentView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)]];
    }
    return _contentView;
}

/// 封面图
- (UIImageView *)coverImgView {
    if (!_coverImgView) {
        _coverImgView = [UIImageView new];
        _coverImgView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _coverImgView;
}

/// 播放按钮
- (UIButton *)playBtn {
    if (!_playBtn) {
        _playBtn = [UIButton new];
        NSBundle *bundle = [NSBundle bundleWithURL:[[NSBundle bundleForClass:self.class] URLForResource:@"AFBrowser" withExtension:@"bundle"]];
        [_playBtn setBackgroundImage:[UIImage imageNamed:@"browser_player_icon" inBundle:bundle compatibleWithTraitCollection:nil] forState:(UIControlStateNormal)];
        [_playBtn addTarget:self action:@selector(playBtnAction:) forControlEvents:(UIControlEventTouchUpInside)];
    }
    return _playBtn;
}

/// 退出按钮
- (UIButton *)dismissBtn {
    if (!_dismissBtn) {
        _dismissBtn = [UIButton new];
        _dismissBtn.alpha = _showVideoControl ? 1 : 0;
        NSBundle *bundle = [NSBundle bundleWithURL:[[NSBundle bundleForClass:self.class] URLForResource:@"AFBrowser" withExtension:@"bundle"]];
        [_dismissBtn setImage:[UIImage imageNamed:@"browser_dismiss" inBundle:bundle compatibleWithTraitCollection:nil] forState:(UIControlStateNormal)];
        [_dismissBtn addTarget:self action:@selector(dismissBtnAction) forControlEvents:(UIControlEventTouchUpInside)];
    }
    return _dismissBtn;
}

/// 加载中
- (UIActivityIndicatorView *)activityView {
    if (!_activityView) {
        _activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _activityView.hidesWhenStopped = YES;
        _activityView.transform = CGAffineTransformMakeScale(2.f, 2.f);
    }
    return _activityView;
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

/// 工具栏
- (AFPlayerBottomBar *)bottomBar {
    if (!_bottomBar) {
        _bottomBar = [AFPlayerBottomBar new];
        _bottomBar.slider.delegate = self;
        _bottomBar.alpha = _showVideoControl ? 1 : 0;
        _bottomBar.playBtn.selected = self.isPlay;
        [_bottomBar.playBtn addTarget:self action:@selector(playBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [_bottomBar.slider addTarget:self action:@selector(sliderTouchDownAction:) forControlEvents:UIControlEventTouchDown];
        [_bottomBar.slider addTarget:self action:@selector(sliderValueChangedAction:) forControlEvents:UIControlEventValueChanged];
        [_bottomBar.slider addTarget:self action:@selector(sliderTouchUpAction:) forControlEvents:UIControlEventTouchUpInside];
        [_bottomBar.slider addTarget:self action:@selector(sliderTouchUpAction:) forControlEvents:UIControlEventTouchCancel];
        [_bottomBar.slider addTarget:self action:@selector(sliderTouchUpAction:) forControlEvents:UIControlEventTouchUpOutside];
        [self addSubview:_bottomBar];
    }
    return _bottomBar;
}

/// 时长
- (float)duration {
    if (self.item.duration > 1) {
        return self.item.duration;
    } else {
        return _player.currentItem ? CMTimeGetSeconds(self.player.currentItem.duration) : 0.f;
    }
}

/// 转场size
- (CGSize)transitionSize {
    if (self.item.width > 0 && self.item.height > 0) {
        return CGSizeMake(self.item.width, self.item.height);
    }
    if (self.coverImgView.image) {
        return self.coverImgView.image.size;
    }
    return self.frame.size;
}

/// 获取播放器frame
- (CGRect)playerFrame {
    if (self.playerLayer.videoGravity == AVLayerVideoGravityResizeAspectFill && self.item.width > 0 && self.item.height > 0) {
        CGFloat height = fmin(self.frame.size.width * self.item.height/self.item.width, self.frame.size.height);
        return CGRectMake(0, (self.frame.size.height - height)/2, self.frame.size.width, height);
    } else {
        return self.bounds;
    }
}

/// 是否正在播放
- (BOOL)isPlay {
    return self.item.playerStatus == AFPlayerStatusPlay;
}


#pragma mark - 更新UI
/// 根据状态，更新UI
- (void)updatePlayerStatus:(AFPlayerStatus)status {
    switch (status) {
            // 加载中
        case AFPlayerStatusLoading: {
            [self.activityView startAnimating];
            self.coverImgView.hidden = NO;
            self.playBtn.hidden = YES;
        }
            break;
            
            // 播放中
        case AFPlayerStatusPlay: {
            [self.activityView stopAnimating];
            self.coverImgView.hidden = YES;
            self.playBtn.hidden = YES;
        }
            break;

            // 初始状态/暂停
        default: {
            if (_showVideoControl) {
                self.bottomBar.playBtn.selected = NO;
            }
            self.playBtn.hidden = NO;
            [_activityView stopAnimating];
            if (!_playerLayer.isReadyForDisplay) {
                self.coverImgView.hidden = NO;
            } else if (self.item.progress == 0 || self.item.progress == 1) {
                self.coverImgView.hidden = NO;
            } else {
                self.coverImgView.hidden = YES;
            }
        }
            break;
    }
}

/// 结束加载动画
- (void)stopLoading {
    [self.activityView stopAnimating];
}

/// 跳转
- (void)seekToTime:(NSTimeInterval)time {
    [self.player seekToTime:CMTimeMakeWithSeconds(time, self.player.currentItem.asset.duration.timescale) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    self.item.currentTime = time;
}

/// 更新bottomBar的进度
- (void)updateProgressWithCurrentTime:(float)currentTime durationTime:(float)durationTime animated:(BOOL)animated{
    if (self.item.showVideoControl) {
        [self.bottomBar updateProgressWithCurrentTime:currentTime durationTime:self.duration animated:animated];
    } else {
        if (_bottomBar.superview) [_bottomBar removeFromSuperview];
        _bottomBar = nil;
    }
}


#pragma mark - 数据
/// 切换PlayerItem
- (void)replacePlayerItem:(AVPlayerItem *)item {
    
    if (item && item == self.player.currentItem) return;
    self.playerItem = item;
    if (self.player.currentItem) {
        [self.player pause];
        [self removeKVO];
        [self.player replaceCurrentItemWithPlayerItem:nil];
        if (item) {
            [self addKVOWithItem:item];
        }
    } else {
        if (item) {
            [self removeKVO];
            [self addKVOWithItem:item];
        }
    }
}

- (void)checkFirstFrame {
    if (!self.didFirstFrame) {
        if (self.playerLayer.isReadyForDisplay) {
            self.didFirstFrame = YES;
            [self updatePlayerStatus:(AFPlayerStatusPlay)];
        }
    }
}


#pragma mark - 下载
///// 预加载
//+ (void)preloadingItem:(MWAudioItem *)item {
//    [self.sharePlayer preloadingItem:item];
//}
//
///// 预加载音视频数据，下载完成后自动保存到本地，不会播放
//- (void)preloadingItem:(MWAudioItem *)item {
//    [MWAudioPlayer safe_performAsyncBlock:^{
//        if (!item) return;
//
//        if (item.localPath.length) {
//            // 已下载完成，修改状态为已下载
//            [item updateItemStatus:MWPlayerItemStatusLoaded];
//        } else {
//            // 如果已经处于加载中，忽略
//            if (item.itemStatus == MWPlayerItemStatusPreloading || item.itemStatus == MWPlayerItemStatusLoading) return;
//            // 开始或继续下载任务
//            [self downloadItem:item priority:MWDownloadPriorityLow];
//        }
//    }];
//}

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
        [loadingItem updatePlayerStatus:status];
        [self updatePlayerStatus:status];
        [self completionError:error];
    } else {
        AFPlayerStatus status = block ? AFPlayerStatusBlock : AFPlayerStatusNormal;
        [loadingItem updatePlayerStatus:status];
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
    NSLog(@"-------------------------- 开始解码 --------------------------");
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
}

/// 解码
- (void)prepareItem {
    __weak typeof(self) weakSelf = self;
    [self.player prerollAtRate:1 completionHandler:^(BOOL finished) {
        if (!finished) {
            NSLog(@"-------------------------- AFPlayer 解码finished：%d -- %@--------------------------", finished, weakSelf.item.content);
        }
        [weakSelf prepareDoneWithError:nil selectedItem:weakSelf.item];
    }];
}

/// 解码完成回调
- (void)prepareDoneWithError:(NSError *)error selectedItem:(AFBrowserVideoItem *)selectedItem {
    // 解码失败
    if (error) {
        //                NSError *error = [NSError errorWithDomain:path code:80401 userInfo:@{@"msg" : @"解码失败"}];
        NSLog(@"-------------------------- 解码失败：%@ -- %@ --------------------------", error, selectedItem.content);
        [selectedItem updateItemStatus:AFBrowserVideoItemStatusFailed];
        [selectedItem updatePlayerStatus:AFPlayerStatusFailed];
        [self updatePlayerStatus:AFPlayerStatusFailed];
        [self completionError:error];
        return;
    }
    // 解码成功，开始播放
    NSLog(@"-------------------------- 解码完成：%@ --------------------------", selectedItem.content);
    if (selectedItem == self.item && selectedItem.playerStatus == AFPlayerStatusLoading) {
        [selectedItem updateItemStatus:AFBrowserVideoItemStatusPrepareDone];
        [self play];
    } else {
        [selectedItem updatePlayerStatus:AFPlayerStatusNormal];
        [selectedItem updateItemStatus:AFBrowserVideoItemStatusLoaded];
    }
    if ([self.delegate respondsToSelector:@selector(prepareDoneWithPlayer:)]) {
        [self.delegate prepareDoneWithPlayer:self];
    }
}


#pragma mark - 播放
/// 播放视频
- (void)playVideoItem:(AFBrowserVideoItem *)item completion:(void(^)(NSError *error))completion {
    self.completion = completion;

    // 停止当前item
    if (self.item != item) {
        [self replacePlayerItem:nil];
        [self stop];
        self.item = item;
        // 更新封面图
        [self attachCoverImage:item.coverImage];
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
                break;
                
                // 解码完成，可直接播放
            case AFBrowserVideoItemStatusPrepareDone: {
                [self play];
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
        [self.item updatePlayerStatus:AFPlayerStatusLoading];
        [self downloadItem:self.item];
    }
}

/// 播放
- (void)play:(BOOL)isRetry {
    // item为空
    if (!self.item) {
        [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"[play]播放错误VideoItem为空, %@", self.displayDescription]];
        [self updatePlayerStatus:(AFPlayerStatusFailed)];
        return;
    }
    // playerItem为空
    if (!self.player.currentItem) {
        [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"[play]播放错误playerItem为空, %@", self.displayDescription]];
        [self playVideoItem:self.item completion:self.completion];
        return;
    }
    // 切换item
    if (self.configuration && self.configuration.transitionStyle != AFBrowserTransitionStyleContinuousVideo && self.configuration.currentItem != self.item) {
        [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"[play]播放错误，已经切换到其他Item, %@", self.displayDescription]];
        [self pause];
        return;
    }
    // 开关关闭
    if (!_AllPlayerSwitch) {
        NSLog(@"-------------------------- 播放过滤，关闭全局播放器 --------------------------");
        return;
    }
    // 状态不对，重新开始播放流程
    if (self.player.currentItem.status != AVPlayerItemStatusReadyToPlay) {
        [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"[play]播放状态错误, playerItem.status = %d", self.player.currentItem.status]];
        [self playVideoItem:self.item completion:self.completion];
        return;
    }
    // 代理控制
    if ([AFBrowserViewController.loaderProxy respondsToSelector:@selector(shouldPlayVideo:)]) {
        if (![AFBrowserViewController.loaderProxy shouldPlayVideo:self.item]) {
            [self pause];
            return;
        }
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
    if (self.progress >= 1) {
        [self seekToTime:0.f];
        [self.bottomBar updateProgressWithCurrentTime:0 durationTime:self.duration animated:NO];
    }
    // 开始播放
    [self startPlay];
}

/// 开始播放，更新UI
- (void)startPlay {
    [self.item updateItemStatus:AFBrowserVideoItemStatusPrepareDone];
    [self.item updatePlayerStatus:AFPlayerStatusPlay];
    if ([self.configuration.delegate respondsToSelector:@selector(browser:willPlayVideoItem:)]) {
        [self.configuration.delegate browser:[self.browserDelegate performSelector:@selector(delegate)] willPlayVideoItem:self.item];
    }
    [self.player play];
    if (_showVideoControl) {
        self.bottomBar.playBtn.selected = YES;
    }
    if (!self.playerLayer.superlayer) {
        [self.layer addSublayer:self.playerLayer];
    }
    [self updatePlayerStatus:(AFPlayerStatusPlay)];
//    NSLog(@"-------------------------- 开始播放 --------------------------", self.item.content);
}


#pragma mark - 暂停
/// 暂停
- (void)pause {
    [self pausePlay];
}

/// 暂停
- (void)pausePlay {
    [self.item updatePlayerStatus:AFPlayerStatusNormal];
    if (self.item.itemStatus > AFBrowserVideoItemStatusLoaded) {
        self.item.itemStatus = AFBrowserVideoItemStatusLoaded;
    }
    [self.player pause];
    [self updatePlayerStatus:(AFPlayerStatusNormal)];
}


#pragma mark - 停止
- (void)stop {
    self.item.progress = 0;
    [self seekToTime:0.f];
    [self.item updatePlayerStatus:AFPlayerStatusNormal];
    if (self.item.itemStatus > AFBrowserVideoItemStatusLoaded) {
        self.item.itemStatus = AFBrowserVideoItemStatusLoaded;
    }
    [self.player pause];
    [self updatePlayerStatus:(AFPlayerStatusNormal)];
}


#pragma mark - 播放结束
- (void)finishedPlay {
    self.item.progress = 0;
    [self seekToTime:0.f];
    if (!self.item.loop) {
        [self.item updatePlayerStatus:AFPlayerStatusNormal];
        if (self.item.itemStatus > AFBrowserVideoItemStatusLoaded) {
            self.item.itemStatus = AFBrowserVideoItemStatusLoaded;
        }
        [self.player pause];
        [self updatePlayerStatus:(AFPlayerStatusNormal)];
    }
}


#pragma mark - 错误回调
- (void)completionError:(NSError *)error {
    if (self.completion) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.completion(error);
        });
    }
}


#pragma mark - KVO
/// 添加观察者
- (void)addKVOWithItem:(AVPlayerItem *)item {
    [item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [self.player replaceCurrentItemWithPlayerItem:item];
    self.isObserving = YES;
    if (!self.playerObserver) {
        __weak typeof(self) weakSelf = self;
        self.playerObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(0.05, NSEC_PER_SEC) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
            [weakSelf checkFirstFrame];
            //视频第一次回调
            weakSelf.item.progress = CMTimeGetSeconds(time) / weakSelf.duration;
            weakSelf.progress = CMTimeGetSeconds(time) / weakSelf.duration;
            if (isnan(weakSelf.progress) || weakSelf.progress > 1.0) {
                weakSelf.item.progress = 0.f;
                weakSelf.progress = 0.f;
                weakSelf.item.currentTime = 0;
            } else {
                weakSelf.item.currentTime = CMTimeGetSeconds(time);
            }
            [weakSelf updateProgressWithCurrentTime:CMTimeGetSeconds(time) durationTime:weakSelf.duration animated:YES];
        }];
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
    if (self.configuration.infiniteLoop) {
        [self seekToTime:0.f];
        [self play];
    } else {
        [self finishedPlay];
    }
}

/// 收到通知：暂停所有正在播放的播放器
+ (void)pauseAllPlayer {
    _AllPlayerSwitch = NO;
    NSLog(@"-------------------------- 暂停所有播放器 --------------------------");
    [NSNotificationCenter.defaultCenter postNotificationName:AFPlayerNotificationPauseAllPlayer object:nil];
}
- (void)pauseAllPlayerNotification {
    if (self.status == AFPlayerStatusPlay) {
        [self pausePlay];
        self.item.currentTime = self.progress * self.duration;
        self.status = AFPlayerStatusPlay;
    }
}

/// 收到通知：恢复所有播放器的状态，如果暂停前是正在播放的，会继续播放
+ (void)resumeAllPlayer {
    _AllPlayerSwitch = YES;
    NSLog(@"-------------------------- 恢复所有播放器 --------------------------");
    [NSNotificationCenter.defaultCenter postNotificationName:AFPlayerNotificationResumeAllPlayer object:nil];
}
- (void)resumeAllPlayerNotification {

    if (self.isPlay) {
        if (self.shouldResume) {
            [self startPlay];
            if (!self.player.isMuted) {
                NSLog(@"-------------------------- 恢复播放：%@ --------------------------", self);
            }
            self.resumeOption = AFPlayerResumeOptionNone;
        }
    }
}

/// 是否恢复
- (BOOL)shouldResume {
    if (self.resumeOption != AFPlayerResumeOptionBrowserAppeared) return YES;
    if ([AFBrowserConfiguration.currentVc isKindOfClass:NSClassFromString(@"AFBrowserViewController")]) return YES;
    return NO;
}

/// Target被释放的通知
- (void)playerControllerProxyDeallocNotification:(NSNotification *)notification {
    NSLog(@"-------------------------- 收到Proxy释放通知：%@ --------------------------", notification.object);
    [self destroy];
}


#pragma mark - 事件
/// 点击播放/暂停按钮
- (void)playBtnAction:(UIButton *)playBtn {
    if (!_AllPlayerSwitch) {
        if ([self.delegate respondsToSelector:@selector(tapActionInDisablePlayer:)]) {
            [self.delegate tapActionInDisablePlayer:self];
        }
        return;
    }
    if (playBtn == self.bottomBar.playBtn) {
        if (playBtn.selected) {
            [self pause];
            self.item.currentTime = self.item.progress * self.duration;
        } else {
            [self play];
        }
    } else {
        [self play];
    }
}

/// 点击player
- (void)tapAction {
    if ([self.browserDelegate respondsToSelector:@selector(tapActionInPlayer:)]) {
        [self.browserDelegate tapActionInPlayer:self];
    }
    if ([self.delegate respondsToSelector:@selector(tapActionInPlayer:)]) {
        [self.delegate tapActionInPlayer:self];
    }
}

/// 左上角退出按钮
- (void)dismissBtnAction {
    if ([self.browserDelegate respondsToSelector:@selector(dismissActionInPlayer:)]) {
        [self.browserDelegate dismissActionInPlayer:self];
    }
    if ([self.delegate respondsToSelector:@selector(dismissActionInPlayer:)]) {
        [self.delegate dismissActionInPlayer:self];
    }
}


#pragma mark - SliderAction
- (BOOL)isSliderTouch {
    return _bottomBar.isSliderTouch;
}

- (void)sliderTouchDownAction:(UISlider *)sender{
    self.bottomBar.isSliderTouch = YES;
}

- (void)sliderValueChangedAction:(UISlider *)sender {
    [self.player pause];
    [self seekToTime:(sender.value * self.duration)];
    [self.bottomBar updateProgressWithCurrentTime:sender.value * self.duration durationTime:self.duration animated:YES];
}

- (void)sliderTouchUpAction:(UISlider *)sender{
    self.bottomBar.isSliderTouch = NO;
    if (self.status == AFPlayerStatusPlay && _AllPlayerSwitch) {
        [self.player play];
    }
}

- (void)slider:(AFPlayerSlider *)slider beginTouchWithValue:(float)value {
    self.bottomBar.isSliderTouch = YES;
    [self.player pause];
    [self seekToTime:(value * self.duration)];
    [self.bottomBar updateProgressWithCurrentTime:value * self.duration durationTime:self.duration animated:NO];
}

- (void)endTouchSlider:(AFPlayerSlider *)slider {
    self.bottomBar.isSliderTouch = NO;
    if (self.status == AFPlayerStatusPlay && _AllPlayerSwitch) {
        [self.player play];
    }
}





@end





