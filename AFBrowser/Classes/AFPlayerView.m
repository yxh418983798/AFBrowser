//
//  AFPlayerView.m
//  AFBrowser
//
//  Created by alfie on 2022/7/8.
//

#import "AFPlayerView.h"
#import <objc/runtime.h>
#import <AVFoundation/AVFoundation.h>
#import "AFBrowserViewController.h"
#import "AFBrowserLoaderProxy.h"
#import "AFBrowserItem.h"
#import "AFBrowserConfiguration.h"
#import "AFPlayer.h"

static int const AFDownloadBlockCode = 6666;

@interface AFPlayerView () <AFPlayerDelegate>

/** 视频数据源 */
@property (nonatomic, strong) AFBrowserVideoItem      *item;

/** 播放器 */
@property (nonatomic, strong) AFPlayer                *player;

/** 是否使用单例播放器，默认true */
@property (nonatomic, assign) BOOL                    useSharePlayer;

/** contentView */
@property (nonatomic, strong) UIView                  *contentView;

/** 封面图 */
@property (strong, nonatomic) UIImageView             *coverImgView;

/** 中间的播放按钮 */
@property (strong, nonatomic) UIButton                *playBtn;

/** 左上角X按钮 */
@property (nonatomic, strong) UIButton                *dismissBtn;

/** 加载进度提示 */
@property (strong, nonatomic) UIActivityIndicatorView *activityView;

/** AFBrowserLoaderProxy */
@property (nonatomic, strong) AFBrowserLoaderProxy    *proxy;

/** 记录是否在监听 */
@property (nonatomic, assign) BOOL          isObserving;

/** 监听进度对象 */
@property (strong, nonatomic) id            playerObserver;

/** isFirstFrame */
@property (nonatomic, assign) BOOL            didFirstFrame;

/** 播放回调 */
@property (nonatomic, copy) void (^completion)(NSError *error);

@end


@implementation AFPlayerView

#pragma mark - 构造方法
- (instancetype)init {
    if (self = [super init]) {
        self.useSharePlayer = YES;
    }
    return self;
}

/// 构造方法，share：是否使用单例播放器
+ (instancetype)playerViewWithSharePlayer:(BOOL)share {
    AFPlayerView *playerView = AFPlayerView.new;
    playerView.useSharePlayer = share;
    return playerView;
}


#pragma mark - 生命周期
- (void)didMoveToSuperview {
    self.clipsToBounds = YES;
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
    if (self.isPlay) {
        [self.player layout];
    }
    
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
    NSLog(@"-------------------------- 播放器释放：%@ --------------------------", self);
    if (!self.useSharePlayer) [self.player destroy];
}

/// 释放
- (void)destroy {
    if (!NSThread.isMainThread) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.superview) [self removeFromSuperview];
            if (!self.useSharePlayer) [self.player destroy];
        });
    } else {
        if (self.superview) [self removeFromSuperview];
        if (!self.useSharePlayer) [self.player destroy];
    }
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

// 控制器即将销毁，做一些转场动画的处理
- (void)browserWillDismiss {
    self.showVideoControl = NO;
//    self.transitionStatus = AFPlayerTransitionStatusTransitioning;
}

/// 控制器已经Dismiss，做一些转场动画的处理
- (void)browserDidDismiss {
    self.showVideoControl = NO;
//    self.transitionStatus = AFPlayerTransitionStatusSmall;
}

/// 控制器取消Dismiss，做一些恢复处理
- (void)browserCancelDismiss {
    if (self.isPlay) {
        [self play];
    }
//    self.showVideoControl = self.item.showVideoControl;
//    self.transitionStatus = AFPlayerTransitionStatusFullScreen;
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
    self.player.videoGravity = videoGravity;
}


#pragma mark - Getter
/// 描述
- (NSString *)displayDescription {
    return @"";
//    return [NSString stringWithFormat:@"播放器描述：%p\n url:%@\n item.content:%@, status:%d, hidden:%d\nProgress：%g, \ncover:%@, \nduration:%g, width:%g, height:%g\ncurrentItem:%@\n showVideoControl:%d", self,  self.url, self.item.content, self.status, self.hidden, self.progress, self.item.coverImage, self.duration, self.item.width, self.item.height, _player.currentItem, self.showVideoControl];
}

/// 播放器
- (AFPlayer *)player {
    if (!_player) {
        if (self.useSharePlayer) {
            _player = AFPlayer.sharePlayer;
        } else {
            _player = AFPlayer.new;
            _player.delegate = self;
        }
    }
    return _player;
}

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
        [_playBtn setImage:[UIImage imageNamed:@"browser_player_icon" inBundle:bundle compatibleWithTraitCollection:nil] forState:(UIControlStateNormal)];
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

/// 是否正在播放
- (BOOL)isPlay {
    return self.item.playerStatus == AFPlayerStatusPlay;
}


#pragma mark - 跳转
- (void)seekToTime:(NSTimeInterval)time {
    [self.player seekToTime:time];
}


#pragma mark - 预加载
/// 准备播放
- (void)prepareVideoItem:(AFBrowserVideoItem *)item {
    if (self.item != item) {
        self.item = item;
        [self attachCoverImage:item.coverImage];
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
    [self.player downloadItem:item];
}


#pragma mark - 播放
/// 播放视频
- (void)playVideoItem:(AFBrowserVideoItem *)item completion:(void(^)(NSError *error))completion {
    if (self.useSharePlayer) {
        self.player.delegate = self;
    }
    // 更新封面图
    if (self.item != item) {
        self.item = item;
        [self attachCoverImage:item.coverImage];
    }
    [self.player playVideoItem:item superview:self completion:completion];
}

- (void)play {
    [self playVideoItem:self.item completion:self.completion];
}

#pragma mark - 暂停
/// 暂停
- (void)pause {
    [self.player pause];
}


#pragma mark - 停止
- (void)stop {
    [self.player stop];
}



#pragma mark - 通知
/// 暂停所有正在播放的播放器
+ (void)pauseAllPlayer {
    [AFPlayer pauseAllPlayer];
}

/// 恢复所有播放器的状态
+ (void)resumeAllPlayer {
    [AFPlayer resumeAllPlayer];
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
    if (!AFPlayer.enable) {
        if ([self.delegate respondsToSelector:@selector(tapActionOnDisablePlayerView:)]) {
            [self.delegate tapActionOnDisablePlayerView:self];
        }
        return;
    }
    if (playBtn == self.bottomBar.playBtn) {
        if (playBtn.selected) {
            [self pause];
        } else {
            [self play];
        }
    } else {
        [self play];
    }
}

/// 点击player
- (void)tapAction {
    if ([self.browserDelegate respondsToSelector:@selector(tapActionOnPlayerView:)]) {
        [self.browserDelegate tapActionOnPlayerView:self];
    }
    if ([self.delegate respondsToSelector:@selector(tapActionOnPlayerView:)]) {
        [self.delegate tapActionOnPlayerView:self];
    }
}

/// 左上角退出按钮
- (void)dismissBtnAction {
    if ([self.browserDelegate respondsToSelector:@selector(dismissActionOnPlayerView:)]) {
        [self.browserDelegate dismissActionOnPlayerView:self];
    }
    if ([self.delegate respondsToSelector:@selector(dismissActionOnPlayerView:)]) {
        [self.delegate dismissActionOnPlayerView:self];
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
    [self seekToTime:(sender.value * self.player.duration)];
    [self.bottomBar updateProgressWithCurrentTime:sender.value * self.player.duration durationTime:self.player.duration animated:YES];
}

- (void)sliderTouchUpAction:(UISlider *)sender{
    self.bottomBar.isSliderTouch = NO;
    if (self.status == AFPlayerStatusPlay && AFPlayer.enable) {
        [self play];
    }
}

- (void)slider:(AFPlayerSlider *)slider beginTouchWithValue:(float)value {
    self.bottomBar.isSliderTouch = YES;
    [self.player pause];
    [self seekToTime:(value * self.player.duration)];
    [self.bottomBar updateProgressWithCurrentTime:value * self.player.duration durationTime:self.player.duration animated:NO];
}

- (void)endTouchSlider:(AFPlayerSlider *)slider {
    self.bottomBar.isSliderTouch = NO;
    if (self.status == AFPlayerStatusPlay && AFPlayer.enable) {
        [self play];
    }
}

#pragma mark - AFPlayerDelegate
/// 更新状态
- (void)player:(AFPlayer *)player updatePlayerStatus:(AFPlayerStatus)status {
    switch (status) {
            // 加载中
        case AFPlayerStatusLoading: {
            NSLog(@"-------------------------- 加载中 --------------------------");
            [self.activityView startAnimating];
            self.coverImgView.hidden = NO;
            self.playBtn.hidden = YES;
        }
            break;
            
            // 播放中
        case AFPlayerStatusPlay: {
            NSLog(@"-------------------------- 播放中 --------------------------");
            [self.activityView stopAnimating];
            self.coverImgView.hidden = YES;
            self.playBtn.hidden = YES;
        }
            break;

            // 初始状态/暂停
        default: {
            NSLog(@"-------------------------- 停止播放 --------------------------");
            if (_showVideoControl) {
                self.bottomBar.playBtn.selected = NO;
            }
            self.playBtn.hidden = NO;
            [_activityView stopAnimating];
            if (!_player.isReadyForDisplay) {
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

/// 更新播放进度
- (void)player:(AFPlayer *)player updateProgressWithCurrentTime:(float)currentTime durationTime:(float)durationTime animated:(BOOL)animated {
    if (self.item.showVideoControl) {
        [self.bottomBar updateProgressWithCurrentTime:currentTime durationTime:self.player.duration animated:animated];
    } else {
        if (_bottomBar.superview) [_bottomBar removeFromSuperview];
        _bottomBar = nil;
    }
}


#pragma mark - 播放器开关
+ (BOOL)enable {
    return AFPlayer.enable;
}
+ (void)setEnable:(BOOL)enable {
    AFPlayer.enable = enable;
}

@end





