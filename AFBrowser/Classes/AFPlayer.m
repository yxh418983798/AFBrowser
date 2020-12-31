//
//  AFPlayer.m
//  AFModule
//
//  Created by alfie on 2020/3/9.
//

#import "AFPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import "AFBrowserLoaderProxy.h"
#import "AFBrowserItem.h"
#import "AFBrowserConfiguration.h"
#import <objc/runtime.h>

//#import <KVOController/KVOController.h>

//@interface AFPlayerProxy: NSObject
//
///** AFPlayer */
//@property (nonatomic, weak) AFPlayer      *weakPlayer;
//
///** AFPlayer */
//@property (nonatomic, strong) AFPlayer    *strongPlayer;
//
///** target */
//@property (nonatomic, weak) id            target;
//
///** item */
//@property (nonatomic, weak) AFBrowserItem       *item;
//
//+ (AFPlayer *)cachePlayerWithItem:(AFBrowserItem *)item;
//
//@end


@interface AFPlayer ()

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
@property (assign, nonatomic) float         duration;

/** 监听进度对象 */
@property (strong, nonatomic) id            playerObserver;

/** proxy */
//@property (nonatomic, strong) AFPlayerProxy      *playerProxy;

/** isFirstFrame */
@property (nonatomic, assign) BOOL            didFirstFrame;
@end


static NSString * const AFPlayerNotificationPauseAllPlayer = @"AFPlayerNotificationPauseAllPlayer";
static NSString * const AFPlayerNotificationResumeAllPlayer = @"AFPlayerNotificationResumeAllPlayer";
static BOOL _AllPlayerSwitch = YES; // 记录播放器总开关
static int playerCount = 0;
//static NSUInteger MaxCount = 5; /// 最大存储数量
//static NSUInteger MaxPlayer = 5;
//static dispatch_queue_t _playerQueue; /// 队列
//static NSMutableArray <AFPlayerProxy *> *_cacheArray; /// 存储容器
//static NSMutableArray <AFPlayerProxy *> *_playerArray;

@implementation AFPlayer

#pragma mark - 生命周期
//+ (void)initialize {
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
////        _cacheArray = NSMutableArray.array;
////        _playerArray = NSMutableArray.new;
////        _playerQueue = dispatch_queue_create("com.Alfie.AFPlayer", DISPATCH_QUEUE_CONCURRENT);
//        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(resumeAllPlayer) name:UIApplicationDidBecomeActiveNotification object:nil];
//        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(pauseAllPlayer) name:UIApplicationWillResignActiveNotification object:nil];
//    });
//}

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
        self.isActive = YES;
    }
    return self;
}
- (void)applicationDidReceiveMemoryWarningNotification {
    NSLog(@"-------------------------- 收到内存警告:%@ --------------------------", self.superview);
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
    [AFPlayer resumeActiveExcludePlayer:self];
    
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
            self.status = AFPlayerStatusNone;
            [AFPlayer resumeActiveExcludePlayer:self];
        });
    } else {
        if (_player) [_player pause];
        [self removeKVO];
        [_player replaceCurrentItemWithPlayerItem:nil];
        [_playerLayer removeFromSuperlayer];
        _player = nil;
        _playerLayer = nil;
        if (self.superview) [self removeFromSuperview];
        self.status = AFPlayerStatusNone;
        [AFPlayer resumeActiveExcludePlayer:self];
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
//    self.status = AFPlayerStatusNone;
//    self.playWhenPrepareDone = YES;
//    [self play];
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
    _item.currentTime = self.progress * self.duration;
    if (!_item || ![_item isEqual:item]) {
        _item = item;
        _url = nil;
//        [self.player replaceCurrentItemWithPlayerItem:nil];
        [self replacePlayerItem:nil];
        if (_item.showVideoControl && _bottomBar.superview) [self addSubview:self.bottomBar];
        self.playWhenPrepareDone = NO;
        self.status = AFPlayerStatusNone;
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
//    NSLog(@"-------------------------- 设置静音：%d  %@--------------------------", muted, self);
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

- (void)setIsActive:(BOOL)isActive {
    if (isActive) {
        _isActive = isActive;
        if (self.url.length && self.isPlay) {
            [self addToPlayerArray];
            [self removeKVO];
            if (self.status == AFPlayerStatusPlay) {
                self.playWhenPrepareDone = YES;
                NSLog(@"-------------------------- 设置自动播放 --------------------------");
            }
            [self prepareDone];
//                [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
//                if (!self.isObserving) {
//                    self.isObserving = YES;
//                    [self.player.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
//                }
//                [self seekToTime:self.item.currentTime];
            NSLog(@"-------------------------- 设置成活跃：%@ tag:%d--------------------------", self, self.tag);
            if (!self.player.muted) {
                NSLog(@"-------------------------- 没有静音：%d --------------------------", self.tag);
            }
        }
    } else {
        if (_isActive != isActive) {
            _isActive = isActive;
            AFPlayerStatus status = self.status;
            [self pausePlay];
            self.status = status;
            [self removeKVO];
            [self replacePlayerItem:nil];
            [_playerLayer removeFromSuperlayer];
            _playerLayer = nil;
            NSLog(@"-------------------------- 设置成不活跃：%@ --------------------------", self);
        }
    }
}

- (void)setVideoGravity:(AVLayerVideoGravity)videoGravity {
    _videoGravity = videoGravity;
    _playerLayer.videoGravity = videoGravity;
}


#pragma mark - UI
- (UIView *)contentView {
    if (!_contentView) {
        _contentView = UIView.new;
        _contentView.backgroundColor = UIColor.clearColor;
        [_contentView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)]];
    }
    return _contentView;
}

- (UIImageView *)coverImgView {
    if (!_coverImgView) {
        _coverImgView = [UIImageView new];
        _coverImgView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _coverImgView;
}

- (UIButton *)playBtn {
    if (!_playBtn) {
        _playBtn = [UIButton new];
        NSBundle *bundle = [NSBundle bundleWithURL:[[NSBundle bundleForClass:self.class] URLForResource:@"AFBrowser" withExtension:@"bundle"]];
        [_playBtn setBackgroundImage:[UIImage imageNamed:@"browser_player_play" inBundle:bundle compatibleWithTraitCollection:nil] forState:(UIControlStateNormal)];
        [_playBtn addTarget:self action:@selector(playBtnAction:) forControlEvents:(UIControlEventTouchUpInside)];
    }
    return _playBtn;
}

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

- (UIActivityIndicatorView *)activityView {
    if (!_activityView) {
        _activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _activityView.hidesWhenStopped = YES;
        _activityView.transform = CGAffineTransformMakeScale(2.f, 2.f);
    }
    return _activityView;
}

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

/// 开始加载动画
- (void)startLoading {
    [self.activityView startAnimating];
}

/// 结束加载动画
- (void)stopLoading {
    [self.activityView stopAnimating];
}


#pragma mark - 数据
- (float)duration {
    if (self.item.duration > 1) {
        return self.item.duration;
    } else {
        return _player.currentItem ? CMTimeGetSeconds(self.player.currentItem.duration) : 0.f;
    }
}

- (CGSize)transitionSize {
    if (self.item.width > 0 && self.item.height > 0) {
        return CGSizeMake(self.item.width, self.item.height);
    }
    if (self.coverImgView.image) {
        return self.coverImgView.image.size;
    }
    return self.frame.size;
}

- (CGRect)playerFrame {
    
    if (self.playerLayer.videoGravity == AVLayerVideoGravityResizeAspectFill && self.item.width > 0 && self.item.height > 0) {
        CGFloat height = fmin(self.frame.size.width * self.item.height/self.item.width, self.frame.size.height);
        return CGRectMake(0, (self.frame.size.height - height)/2, self.frame.size.width, height);
    } else {
        return self.bounds;
    }
}

- (BOOL)isPlay {
    return self.status == AFPlayerStatusPlay || (self.status == AFPlayerStatusFinished && self.configuration.infiniteLoop) || (self.status == AFPlayerStatusPrepareDone && self.playWhenPrepareDone);
}

- (void)checkFirstFrame {
    if (!self.didFirstFrame) {
        if (self.playerLayer.isReadyForDisplay) {
            self.didFirstFrame = YES;
            [self onFirstFrame];
        }
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
            weakSelf.progress = CMTimeGetSeconds(time) / weakSelf.duration;
//                NSLog(@"-------------------------- progress：%g--------------------------", weakSelf.progress);
            if (isnan(weakSelf.progress) || weakSelf.progress > 1.0) {
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
            NSLog(@"-------------------------- 发现异常 --------------------------");
        }
    }
    self.isObserving = NO;
    self.playerObserver = nil;
//    if (self.isObserving) {
//        self.isObserving = NO;
//        [_player.currentItem removeObserver:self forKeyPath:@"status"];
//    }
//    if (self.playerObserver) {
//        [_player removeTimeObserver:self.playerObserver];
//        self.playerObserver = nil;
//    }
}

/// 监听回调
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"status"]) {
        [self statusDidChange];
    }
}

/// 状态改变
- (void)statusDidChange {
    switch (self.player.currentItem.status) {
            
        case AVPlayerItemStatusReadyToPlay:
//            NSLog(@"-------------------------- 播放器可以播放的状态:%@ --------------------------", _coverImgView);
            [self.bottomBar updateProgressWithCurrentTime:0.f durationTime:self.duration animated:YES];
            if ([self.delegate respondsToSelector:@selector(prepareDoneWithPlayer:)]) {
                [self.delegate prepareDoneWithPlayer:self];
                
            }
            if (self.playWhenPrepareDone) {
                [self play];
                NSLog(@"-------------------------- 准备完成了自动播放：%@ --------------------------", self);
            } else {
                self.playBtn.hidden = NO;
                [self stopLoading];
                NSLog(@"-------------------------- 准备完成了，先不播放：%@ --------------------------", self);
            }//http://alicvid6.mowang.online/vid/3448868F0E885E0E6152D2F7D186C56E.mp4       video/c1a167bd94b63dcc70cd885212188c70.mp4
            break;
            
        case AVPlayerItemStatusFailed:
            [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"播放错误 ,%@\n %@", self.player.error, self.displayDescription]];
//            if (self.player.currentItem.error.code == -11839) {
                // 无法解码，解码器正忙
//                if (self.status == AFPlayerStatusPlay || self.status == AFPlayerStatusPrepareDone) {
//                    [self play];
//                }
//            }
            break;
            
        default:
            break;
    }
}


#pragma mark - 首帧回调
- (void)onFirstFrame {
    self.coverImgView.hidden = YES;
    self.playBtn.hidden = YES;
    [self stopLoading];
}

#pragma mark - 切换PlayerItem
- (void)replacePlayerItem:(AVPlayerItem *)item {
    
    if (item && item == self.player.currentItem) return;
    self.playerItem = item;
//    NSLog(@"-------------------------- 重置Item:%@ --------------------------", item);
    if (self.player.currentItem) {
        [self.player pause];
        [self removeKVO];
        [self.player replaceCurrentItemWithPlayerItem:nil];
        if (item) {
            [self addToPlayerArray];
            [self addKVOWithItem:item];
        }
    } else {
        if (item) {
            [self addToPlayerArray];
            [self removeKVO];
            [self addKVOWithItem:item];
        }
    }
}


#pragma mark - 准备播放
- (void)prepare {
//    [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"prepare准备数据, %@", self.displayDescription]];
    if (!self.item.content) {
        [self stopLoading];
        [self attachCoverImage:self.item.coverImage];
        self.coverImgView.hidden = NO;
        [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"[prepare]错误，item的Content为空, %@", self.displayDescription]];
        self.playBtn.hidden = YES;
        [self replacePlayerItem:nil];
        return;
    } else {
        if (self.player.currentItem) {
            if (![self.configuration isEqualUrl:self.url toUrl:[self.configuration videoPathForItem:self.item]]) {
                [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"[prepare]数据错误, %@", self.displayDescription]];
                self.url = nil;
//                [self.player replaceCurrentItemWithPlayerItem:nil];
                [self replacePlayerItem:nil];
                self.coverImgView.image = nil;
                self.status = AFPlayerStatusNone;
            }
        }
    }

    switch (self.status) {

        case AFPlayerStatusNone: {
            self.status = AFPlayerStatusPrepare;
            [self startLoading];
            self.playBtn.hidden = YES;
            self.coverImgView.image = nil;
            self.coverImgView.hidden = NO;
            if (self.player.currentItem) {
//                [self.player replaceCurrentItemWithPlayerItem:nil];
                [self replacePlayerItem:nil];
            }
            NSString *urlString = [self.item.content isKindOfClass:NSString.class] ? self.item.content : [(NSURL *)self.item.content absoluteString];
            if ([urlString hasPrefix:@"file://"]) {
                self.url = urlString;
                [self attachCoverImage:self.item.coverImage];
                [self prepareDone];
                return;
            } else if ([urlString hasPrefix:@"/var/mobile/"]) {
                self.url = [NSString stringWithFormat:@"file://%@", urlString];
                [self attachCoverImage:self.item.coverImage];
                [self prepareDone];
                return;
            }
            [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"[prepare]无状态, %@", self.displayDescription]];
            __weak typeof(self) weakSelf = self;
            [AFBrowserLoaderProxy loadVideo:urlString progress:nil completion:^(NSString *url, NSError *error) {
                if (error) {
                    weakSelf.status == AFPlayerStatusNone;
                    [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"[prepare]无状态，下载错误：%@，描述：%@", error, weakSelf.displayDescription]];
                } else {

                    if (![weakSelf.configuration isEqualUrl:url toUrl:[AFDownloader filePathWithUrl:weakSelf.item.content]]) {
                        weakSelf.status == AFPlayerStatusNone;
                        [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"[prepare]无状态，URL已切换：%@，描述：%@", url, weakSelf.displayDescription]];
                    } else if (url.length) {
                        weakSelf.url = url;
                        [weakSelf prepareDone];
                        [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"[prepare]无状态，视频下载完成：%@，描述：%@", url, weakSelf.displayDescription]];
                    } else {
                        weakSelf.status == AFPlayerStatusNone;
                        [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"[prepare]无状态，下载视频结果错误：url为空 , %@", weakSelf.displayDescription]];
                    }
                }
            }];
            [self attachCoverImage:self.item.coverImage];
        }
            break;
            
        case AFPlayerStatusPrepare:
            [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"[prepare]准备状态, %@", self.displayDescription]];
            [self startLoading];
            self.playBtn.hidden = YES;
            self.coverImgView.hidden = NO;
            if ([self.url containsString:@"file://"]) {
                [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"[prepare]正在Prepare, %@", self.displayDescription]];
            }
            break;
            
        case AFPlayerStatusReadToPlay:
        case AFPlayerStatusPlay:
            [self startPlay];
            break;
            
        default:
            break;
    }
}


#pragma mark - 准备完成
- (void)prepareDone {
//    [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"prepareDone数据准备完成, %@", self.displayDescription]];
    self.status = AFPlayerStatusPrepareDone;
//    [self stopLoading];
    if (self.url.length) {
        if (!self.isActive) return;
//        [self.player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:[NSURL URLWithString:self.url]]];
        [self replacePlayerItem:[AVPlayerItem playerItemWithURL:[NSURL URLWithString:self.url]]];
//        self.progress = self.duration > 0 ? self.item.currentTime / self.duration : 0;
        [self seekToTime:self.item.currentTime];
        [self updateProgressWithCurrentTime:self.item.currentTime durationTime:self.duration animated:YES];
        if (self.playWhenPrepareDone) {
            // 准备完成，直接播放
            [self play];
            [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"[prepareDone]，准备完成，调用play：%@", self.displayDescription]];
        }
    } else {
        [self replacePlayerItem:nil];
        [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"[prepareDone]，准备完成，url为空：%@", self.displayDescription]];
    }
}


#pragma mark - 播放
- (void)play {
//    [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"play：播放, %@", self.displayDescription]];
    if (!self.isActive) {
        [self addToPlayerArray];
    }
    
    self.playWhenPrepareDone = YES;
    switch (self.status) {
            
        // 初始状态，进行准备数据，准备完成再播放
        case AFPlayerStatusNone:
            [self prepare];
            break;
            
        // 准备完成或暂停，直接进行播放
        case AFPlayerStatusPrepareDone:
        case AFPlayerStatusReadToPlay:
        case AFPlayerStatusPause:
            if (self.progress >= 1) {
                [self seekToTime:0.f];
            }
            [self startPlay];
            break;
            
        case AFPlayerStatusPlay:
            [self startPlay];
            break;;

        // 停止播放，数据可能没有准备完成，经需要重新prepare
        case AFPlayerStatusStop:
            [self prepare];
            break;

        // 播放结束，数据已经准备完成，只需要跳转到开头的位置重新播放
        case AFPlayerStatusFinished: {
            [self seekToTime:0.f];
            [self.bottomBar updateProgressWithCurrentTime:0 durationTime:self.duration animated:NO];
            [self startPlay];
        }
            break;
            
        default: // AFPlayerStatusPlay AFPlayerStatusPrepare
            break;
    }
}

/// 播放，更新UI
- (void)startPlay {
//    NSLog(@"-------------------------- startPlay：%g --------------------------", self.progress);
    if (!_AllPlayerSwitch) return;
    if (!self.player.currentItem) {
        [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"[startPlay]播放错误currentItem为空, %@", self.displayDescription]];
        self.status = AFPlayerStatusNone; // 重新加载数据
        [self prepare];
        return;
    }
    
    if (!self.item) {
        if (self.url) {
//            [self.player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:[NSURL URLWithString:self.url] ?: NSURL.new]];
            [self replacePlayerItem:[AVPlayerItem playerItemWithURL:[NSURL URLWithString:self.url]]];

        } else {
            [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"[startPlay]播放错误URL为空, %@", self.displayDescription]];
        }
    }
    
    if (self.configuration && self.configuration.transitionStyle != AFBrowserTransitionStyleContinuousVideo && self.configuration.currentItem != self.item) {
        [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"[startPlay]停止播放，已经切换到其他Item, %@", self.displayDescription]];
        [self pause];
        return;
    }
//    if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay || (self.player.currentItem.status == AVPlayerItemStatusUnknown && self.configuration.transitionStyle == AFBrowserTransitionStyleContinuousVideo)) {
    if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
        if (self.playerLayer.isReadyForDisplay) {
            [self realPlay];
        } else {
            [self readyToPlay];
            /// 为了避免一直在等待中，这里执行两次检查
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (self.playerLayer.isReadyForDisplay) {
                    if (self.isPlay) {
                        [self realPlay];
                    }
                } else {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        if (self.playerLayer.isReadyForDisplay) {
                            if (self.isPlay) {
                                [self realPlay];
                            }
                        }
                    });
                }
            });
            NSLog(@"-------------------------- 播放器还没准备好 111--------------------------");
        }
//        [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"[startPlay]隐藏图片, %@", self.displayDescription]];
    } else {
        [self readyToPlay];
        NSLog(@"-------------------------- 播放器还没准备好 222--------------------------");
    }
}


- (void)realPlay {
    self.status = AFPlayerStatusPlay;
    [self.player play];
    if ([self.configuration.delegate respondsToSelector:@selector(browser:willPlayVideoItem:)]) {
        [self.configuration.delegate browser:[self.browserDelegate performSelector:@selector(delegate)] willPlayVideoItem:self.item];
    }
    if (_showVideoControl) {
        self.bottomBar.playBtn.selected = YES;
    }
    if (!self.playerLayer.superlayer) {
        [self.layer addSublayer:self.playerLayer];
    }
    [self onFirstFrame];
//    NSLog(@"-------------------------- 开始播放，隐藏图片 111:%@ --------------------------", self.item.content);
}


- (BOOL)isReadyToPlay {
    return _playerLayer.isReadyForDisplay;
}

- (void)readyToPlay {
    [self startLoading];
    self.coverImgView.hidden = NO;
    self.playBtn.hidden = YES;
}

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
            self.item.currentTime = self.progress * self.duration;
        } else {
            [self play];
        }
    } else {
        [self play];
    }
}


#pragma mark - 暂停
- (void)pause {
//    [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"暂停播放, %@", self.displayDescription]];
    self.playWhenPrepareDone = NO;
    switch (self.status) {
            
        // 播放中，需要暂停
        case AFPlayerStatusPlay:
            [self pausePlay];
            break;

        default:
            break;
    }
}

/// 暂停
- (void)pausePlay {
//    NSLog(@"-------------------------- pausePlay --------------------------");
    if (_showVideoControl) {
        self.bottomBar.playBtn.selected = NO;
    }
    [self.player pause];
    if (self.player.currentItem && self.url.length) {
        self.item.currentTime = self.progress * self.duration;
        self.status = AFPlayerStatusPause;
        self.playBtn.hidden = NO;
        [self stopLoading];
    }
    self.coverImgView.hidden = self.isActive ? self.progress < 1 : NO;
}


#pragma mark - 停止
- (void)stop {
    [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"[stop]停止播放, %@", self.displayDescription]];
    self.playWhenPrepareDone = NO;
    [AFDownloader cancelTask:self.url];
    
    switch (self.status) {
            
        case AFPlayerStatusNone:
        case AFPlayerStatusStop:
            break;

        default:
            [self stopPlay];
            break;
    }
    
    if (self.player.currentItem) {
        [self.player pause];
    }
    self.item.currentTime = 0;
//    if (self.playerObserver) {
//        [self.player removeTimeObserver:self.playerObserver];
//        self.playerObserver = nil;
//    }
//    [self.player replaceCurrentItemWithPlayerItem:nil];
    [self replacePlayerItem:nil];
}

/// 停止播放
- (void)stopPlay {
    if (_showVideoControl) {
        self.bottomBar.playBtn.selected = NO;
    }
    self.status = AFPlayerStatusStop;
    self.playBtn.hidden = NO;
    [self stopLoading];
    [self.player pause];
    self.coverImgView.hidden = NO;
    [self seekToTime:0.f];
}


#pragma mark - 播放结束
- (void)finishedPlay {
    [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"[finishedPlay]播放结束 , %@", self.displayDescription]];
    if (_showVideoControl) {
        self.bottomBar.playBtn.selected = NO;
    }
    self.status = AFPlayerStatusFinished;
    self.playBtn.hidden = NO;
    [self stopLoading];
    [self.player pause];
    [self seekToTime:0.f];
    self.item.currentTime = 0;
    self.coverImgView.hidden = self.progress < 1;
}


#pragma mark - 跳转
- (void)seekToTime:(NSTimeInterval)time {
    [self.player seekToTime:CMTimeMakeWithSeconds(time, self.player.currentItem.asset.duration.timescale) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    self.item.currentTime = time;
}


#pragma mark - 更新bottomBar的进度
- (void)updateProgressWithCurrentTime:(float)currentTime durationTime:(float)durationTime animated:(BOOL)animated{
    if (self.item.showVideoControl) {
        [self.bottomBar updateProgressWithCurrentTime:currentTime durationTime:self.duration animated:animated];
    } else {
        if (_bottomBar.superview) [_bottomBar removeFromSuperview];
        _bottomBar = nil;
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


#pragma mark - 点击player
- (void)tapAction {
    if ([self.browserDelegate respondsToSelector:@selector(tapActionInPlayer:)]) {
        [self.browserDelegate tapActionInPlayer:self];
    }
    if ([self.delegate respondsToSelector:@selector(tapActionInPlayer:)]) {
        [self.delegate tapActionInPlayer:self];
    }
}


#pragma mark - 左上角退出按钮
- (void)dismissBtnAction {
    if ([self.browserDelegate respondsToSelector:@selector(dismissActionInPlayer:)]) {
        [self.browserDelegate dismissActionInPlayer:self];
    }
    if ([self.delegate respondsToSelector:@selector(dismissActionInPlayer:)]) {
        [self.delegate dismissActionInPlayer:self];
    }
}


#pragma mark - 收到通知：播放器 播放结束
- (void)finishedPlayAction:(NSNotification *)notification {
    if (notification.object != self.player.currentItem) {
        return;
    }
    self.status = AFPlayerStatusFinished;
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


#pragma mark - 收到通知：暂停所有正在播放的播放器
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


#pragma mark - 收到通知：恢复所有播放器的状态，如果暂停前是正在播放的，会继续播放
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


- (BOOL)shouldResume {
    if (self.resumeOption != AFPlayerResumeOptionBrowserAppeared) return YES;
    if ([AFBrowserConfiguration.currentVc isKindOfClass:NSClassFromString(@"AFBrowserViewController")]) return YES;
    return NO;
}


#pragma mark - Player内存管理
//- (AFPlayerProxy *)playerProxy {
//    if (!_playerProxy) {
//        _playerProxy = AFPlayerProxy.new;
//        _playerProxy.weakPlayer = self;
//    }
//    return _playerProxy;
//}

/// 添加到数组
- (void)addToPlayerArray {
//    self.isActive = YES;
//    if ([_playerArray containsObject:self.playerProxy]) {
//        // 如果已经存在，更新index到首位
//        NSInteger index = [_playerArray indexOfObject:self.playerProxy];
//        if (index != 0) {
//            [_playerArray removeObjectAtIndex:index];
//            [_playerArray insertObject:self.playerProxy atIndex:0];
//        }
//    } else {
//        // 没有在数组中，则直接添加在首位
//        [_playerArray insertObject:self.playerProxy atIndex:0];
//        // 添加后播放器后，检查是否超过了限制数量，如果超过，需要设置成不活跃状态，避免播放器数量太多造成解码失败
//        if (_playerArray.count > MaxPlayer) {
//            for (int i = MaxPlayer; i < _playerArray.count; i++) {
//                _playerArray[i].weakPlayer.isActive = NO;
//            }
//        }
//    }
}

/// 有播放器释放的时候，将等待中的不活跃播放器重新设置为活跃
+ (void)resumeActiveExcludePlayer:(AFPlayer *)excludePlayer {
//    if (excludePlayer->_playerProxy && [_playerArray containsObject:excludePlayer.playerProxy]) {
//        [_playerArray removeObject:excludePlayer.playerProxy];
//    }
//    for (int i = 0; i < _playerArray.count && i < MaxPlayer; i++) {
//        _playerArray[i].weakPlayer.isActive = YES;
//    }
}


#pragma mark - Target被释放的通知
- (void)playerControllerProxyDeallocNotification:(NSNotification *)notification {
    NSLog(@"-------------------------- 收到Proxy释放通知：%@ --------------------------", notification.object);
    [self destroy];
}


@end



//@implementation AFPlayerProxy
//
//- (void)dealloc {
//    [AFPlayerProxy removeCache:self];
//}
//
//
//#pragma mark - 获取player
//+ (AFPlayer *)cachePlayerWithItem:(AFBrowserItem *)item {
//    if (!item || item.type != AFBrowserItemTypeVideo || !item.content) return [AFPlayer playerWithItem:item];
////    if (!target) target = item;
//    AFPlayerProxy *proxy = objc_getAssociatedObject(item, "AFPlayerProxy");
//    if (!proxy) {
//        proxy = AFPlayerProxy.new;
//        objc_setAssociatedObject(item, "AFPlayerProxy", proxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
//    }
//    proxy.item = item;
//    if (!proxy.strongPlayer) proxy.strongPlayer = [AFPlayer playerWithItem:item];
//    [self addCache:proxy];
//    return proxy.strongPlayer;
//}
//
//
//#pragma mark - 缓存tool
//+ (void)addCache:(AFPlayerProxy *)proxy {
//    if (!proxy) return;
//    __block BOOL contains = NO;
//    dispatch_sync(_playerQueue, ^{
//        contains = ![_cacheArray containsObject:proxy];
//    });
//    if (contains) {
//        // 数量超出限制的话，需要先清除数据
//        while (self.cacheArrayCount >= MaxCount) {
//            dispatch_barrier_async(_playerQueue, ^{
//                [_cacheArray removeObjectAtIndex:0];
//            });
//        }
//        // 添加到数组进行缓存
//        dispatch_barrier_async(_playerQueue, ^{
//            [_cacheArray addObject:proxy];
//        });
//    }
//}
//
//+ (NSUInteger)cacheArrayCount {
//    __block NSInteger count = 0;
//    dispatch_sync(_playerQueue, ^{
//        count = _cacheArray.count;
//    });
//    return count;
//}
//
//
//#pragma mark - 删除tool
//+ (void)removeCache:(AFPlayerProxy *)proxy {
//    if (!proxy) return;
//    dispatch_sync(_playerQueue, ^{
//        if ([_cacheArray containsObject:proxy]) {
//            // 清除数据
//            dispatch_barrier_async(_playerQueue, ^{
//                [_cacheArray removeObject:proxy];
//            });
//        }
//    });
//}
//
//@end



