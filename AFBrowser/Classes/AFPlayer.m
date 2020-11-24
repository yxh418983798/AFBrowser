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
#import "AFBrowserViewController.h"
#import "AFBrowserLoaderProxy.h"
//#import <KVOController/KVOController.h>

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

/** 是否活跃，默认YES */
@property (nonatomic, assign) BOOL          isActive;

/** 记录进度 */
@property (assign, nonatomic) CGFloat       progress;

/** 记录时长 */
@property (assign, nonatomic) float         duration;

/** 监听进度对象 */
@property (strong, nonatomic) id            playerObserver;

@end



@implementation AFPlayer

static NSString * const AFPlayerNotificationPauseAllPlayer = @"AFPlayerNotificationPauseAllPlayer";
static NSString * const AFPlayerNotificationResumeAllPlayer = @"AFPlayerNotificationResumeAllPlayer";
static BOOL _AllPlayerSwitch = YES; // 记录播放器总开关
static int MaxPlayer = 5;

#pragma mark - 生命周期
+ (void)initialize {
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(resumeAllPlayer) name:UIApplicationWillEnterForegroundNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(pauseAllPlayer) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        NSLog(@"-------------------------- 创建播放器 --------------------------");
        [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"创建播放器, %@", self.displayDescription]];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(pauseAllPlayerNotification) name:AFPlayerNotificationPauseAllPlayer object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(resumeAllPlayerNotification) name:AFPlayerNotificationResumeAllPlayer object:nil];
//        self.proxy = [AFBrowserLoaderProxy aVPlayerItemDidPlayToEndTimeNotificationWithTarget:self selector:@selector(finishedPlayAction:)];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(finishedPlayAction:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        self.isActive = YES;
    }
    return self;
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
//    NSLog(@"-------------------------- didMoveToSuperview:%@ --------------------------", self.superview);
}

- (void)layoutSubviews {
    [CATransaction begin];
    [CATransaction setAnimationDuration:0];
    [CATransaction setDisableActions:YES];
//    self.playerLayer.frame = self.bounds;
    self.playerLayer.frame = self.playerFrame;
    [CATransaction commit];
    CGFloat size = 50.f;
    self.contentView.frame = self.bounds;
    self.coverImgView.frame = self.bounds;
    self.playBtn.frame = CGRectMake((self.frame.size.width - size)/2, (self.frame.size.height - size)/2, size, size);
    self.activityView.frame = CGRectMake((self.frame.size.width - size)/2, (self.frame.size.height - size)/2, size, size);
    if (self.item.showVideoControl) {
        self.dismissBtn.frame = CGRectMake(0, UIApplication.sharedApplication.statusBarFrame.size.height == 44 ? 44 : 20, 50, 44);
        self.bottomBar.frame = CGRectMake(0, self.frame.size.height - 80, self.frame.size.width, 50);
    }
    [super layoutSubviews];
}

- (void)dealloc {
    [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"播放器释放了, %@", self.displayDescription]];
    NSLog(@"-------------------------- 释放了播放器:%p --------------------------", self);
    [self replacePlayerItem:nil];
    [_playerLayer removeFromSuperlayer];
    _player = nil;
    _playerLayer = nil;
    [AFPlayer resumeActiveExcludePlayer:self];
}

- (NSString *)displayDescription {
    return [NSString stringWithFormat:@"播放器描述：%p\n showToolBar:%d, status:%d, hidden:%d\nProgress：%g, \ncover:%@, \nduration:%g, width:%g, height:%g\ncurrentItem:%@", self, self.showToolBar, self.status, self.hidden, self.progress, self.item.coverImage, self.duration, self.item.width, self.item.height, self.player.currentItem];
}


// 控制器即将销毁，做一些转场动画的处理
- (void)browserWillDismiss {
    self.showToolBar = NO;
    self.transitionStatus = AFPlayerTransitionStatusTransitioning;
//    [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"willDismiss转场隐藏Toolbar, %@", self.displayDescription]];
}

/// 控制器已经Dismiss，做一些转场动画的处理
- (void)browserDidDismiss {
    self.showToolBar = NO;
    self.transitionStatus = AFPlayerTransitionStatusSmall;
//    [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"didDismiss转场隐藏Toolbar, %@", self.displayDescription]];
}

/// 控制器取消Dismiss，做一些恢复处理
- (void)browserCancelDismiss {
    self.showToolBar = self.showToolBar;
    self.transitionStatus = AFPlayerTransitionStatusFullScreen;
//    [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"取消转场恢复Toolbar, %@", self.displayDescription]];
}


#pragma mark - setter
- (void)setShowToolBar:(BOOL)showToolBar {
    BOOL isFull = (self.frame.size.width == UIScreen.mainScreen.bounds.size.width) || (self.frame.size.height == UIScreen.mainScreen.bounds.size.height);
    if ((!isFull || self.transitionStatus != AFPlayerTransitionStatusFullScreen) && showToolBar) {
//        [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"异常Toolbar, %@", self.displayDescription]];
        return;
    } else {
        _showToolBar = showToolBar;
    }
    _bottomBar.alpha = _showToolBar ? 1 : 0;
    _dismissBtn.alpha = _showToolBar ? 1 : 0;
//    [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"设置了ToolBar:%d, %@", showToolBar, self.displayDescription]];
}

- (void)setItem:(AFBrowserItem *)item {
    _item.currentTime = self.progress * self.duration;
    if (!_item || _item.content != item.content) {
        _item = item;
        _url = nil;
//        [self.player replaceCurrentItemWithPlayerItem:nil];
        [self replacePlayerItem:nil];
        self.playWhenPrepareDone = NO;
        if (_item.showVideoControl && _bottomBar.superview) [self addSubview:self.bottomBar];
        self.status = AFPlayerStatusNone;
        _coverImgView.image = nil;
        [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"设置item: %@", self.displayDescription]];
    } else {
        _item = item;
    }
}

- (void)setMuted:(BOOL)muted {
    _muted = muted;
    self.player.muted = muted;
}

- (void)attachCoverImage:(id)image {
    if ([self.item.coverImage isKindOfClass:NSString.class]) {
        [AFBrowserLoaderProxy loadImage:[NSURL URLWithString:(NSString *)self.item.coverImage] completion:^(UIImage *image, NSError *error) {
            self.coverImgView.image = image;
            NSLog(@"-------------------------- 显示图片 --------------------------");
        }];
    } else if ([self.item.coverImage isKindOfClass:NSURL.class]) {
        [AFBrowserLoaderProxy loadImage:(NSURL *)self.item.coverImage completion:^(UIImage *image, NSError *error) {
            self.coverImgView.image = image;
        }];
    } else if ([self.item.coverImage isKindOfClass:UIImage.class]) {
        self.coverImgView.image = self.item.coverImage;
    } else {
        self.coverImgView.image = [UIImage new];
    }
}

- (void)setIsActive:(BOOL)isActive {
    if (_isActive != isActive) {
        _isActive = isActive;
        if (isActive) {
            if (self.playerItem) {
                [self addToPlayerArray];
                [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
                if (!self.isObserving) {
                    self.isObserving = YES;
                    [self.player.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
                }
                [self seekToTime:self.item.currentTime];
                if (self.status == AFPlayerStatusPlay) {
                    [self startPlay];
                }
                NSLog(@"-------------------------- 设置成活跃：%@ %@--------------------------", self, NSThread.currentThread);
            }
        } else {
            AFPlayerStatus status = self.status;
            [self pausePlay];
            self.status = status;
            if (self.player.currentItem) {
                if (self.isObserving) {
                    self.isObserving = NO;
                    [self.player.currentItem removeObserver:self forKeyPath:@"status"];
                }
                [self.player replaceCurrentItemWithPlayerItem:nil];
                NSLog(@"-------------------------- 设置成不活跃：%@ --------------------------", self);
            }
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
        _dismissBtn.alpha = _showToolBar ? 1 : 0;
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
    }
    return _player;
}

- (AVPlayerLayer *)playerLayer {
    if (!_playerLayer) {
        _playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
//        _playerLayer.videoGravity = AVLayerVideoGravityResize;
//        _playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        _playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        _playerLayer.masksToBounds= YES;
    }
    return _playerLayer;
}

- (AFPlayerBottomBar *)bottomBar {
    if (!_bottomBar) {
        _bottomBar = [AFPlayerBottomBar new];
        _bottomBar.slider.delegate = self;
        _bottomBar.alpha = _showToolBar ? 1 : 0;
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

/// 保存播放器的数组
+ (NSPointerArray *)playerArray {
    static NSPointerArray *_playerArray;
    if (!_playerArray) {
        _playerArray = [NSPointerArray pointerArrayWithOptions:NSPointerFunctionsWeakMemory];
    }
    return _playerArray;
}

/// 添加到数组
- (void)addToPlayerArray {
    NSArray *playerArray = AFPlayer.playerArray.allObjects;
    self.isActive = YES;
    if (![playerArray containsObject:self]) {
        // 没有在数组中，则直接添加在首位
        [AFPlayer.playerArray insertPointer:(__bridge void *)(self) atIndex:0];
        playerArray = AFPlayer.playerArray.allObjects;
        // 添加后播放器后，检查是否超过了限制数量，如果超过，需要设置成不活跃状态，避免播放器数量太多造成解码失败
        if (playerArray.count > MaxPlayer) {
            for (int i = MaxPlayer; i < playerArray.count; i++) {
                AFPlayer *player = playerArray[i];
                player.isActive = NO;
            }
        }
    } else {
        // 如果已经存在，更新index到首位
        if (AFPlayer.playerArray.count != playerArray.count) {
            for (NSInteger i = AFPlayer.playerArray.count - 1; i >= 0 ; i--) {
                if (![AFPlayer.playerArray pointerAtIndex:i]) {
                    [AFPlayer.playerArray removePointerAtIndex:i];
                }
            }
        }
        NSInteger index = [AFPlayer.playerArray.allObjects indexOfObject:self];
        if (index != 0) {
            [AFPlayer.playerArray removePointerAtIndex:index];
            [AFPlayer.playerArray insertPointer:(__bridge void *)(self) atIndex:0];
        }
    }
}

/// 有播放器释放的时候，将等待中的不活跃播放器重新设置为活跃
+ (void)resumeActiveExcludePlayer:(AFPlayer *)excludePlayer {
    NSArray *playerArray = AFPlayer.playerArray.allObjects;
    for (int i = 0; i < playerArray.count && i < MaxPlayer; i++) {
        AFPlayer *player = playerArray[i];
        if (player != excludePlayer) {
            player.isActive = YES;
        }
    }
}

+ (AFPlayer *)cachePlayerWithItem:(AFBrowserItem *)item {
    AFPlayer *result;
    NSArray *array = AFPlayer.playerArray.allObjects;
    for (AFPlayer *player in array) {
        if ([player.item.content isEqualToString:item.content]) {
            return player;
        }
    }
    return nil;
}


#pragma mark - KVO
/// 添加观察者
- (void)addKVOWithItem:(AVPlayerItem *)item {
    [item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [self.player replaceCurrentItemWithPlayerItem:item];
    self.isObserving = YES;
    if (!self.playerObserver) {
        __weak typeof(self) weakSelf = self;
        self.playerObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(0.5, NSEC_PER_SEC) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
            weakSelf.progress = CMTimeGetSeconds(time) / weakSelf.duration;
//                NSLog(@"-------------------------- progress：%g--------------------------", weakSelf.progress);
            if (isnan(weakSelf.progress) || weakSelf.progress > 1.0) {
                weakSelf.progress = 0.f;
                weakSelf.item.currentTime = 0;
            } else {
                weakSelf.item.currentTime = CMTimeGetSeconds(time);
            }
            [weakSelf updateProgressWithCurrentTime:CMTimeGetSeconds(time) durationTime:weakSelf.duration];
        }];
    }
}

/// 移除观察者
- (void)removeKVO {
    if (self.isObserving) {
        self.isObserving = NO;
        [self.player.currentItem removeObserver:self forKeyPath:@"status"];
    }
    if (self.playerObserver) {
        [self.player removeTimeObserver:self.playerObserver];
        self.playerObserver = nil;
    }
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
            NSLog(@"-------------------------- 播放器可以播放的状态:%@ --------------------------", _coverImgView);
            [self.bottomBar updateProgressWithCurrentTime:0.f durationTime:self.duration];
            if ([self.delegate respondsToSelector:@selector(prepareDoneWithPlayer:)]) {
                [self.delegate prepareDoneWithPlayer:self];
                
            }
            if (self.playWhenPrepareDone) {
                [self play];
            } else {
                self.playBtn.hidden = NO;
            }
            [self stopLoading];
            break;
            
        case AVPlayerItemStatusFailed:
            [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"播放错误 ,%@\n %@", self.player.error, self.displayDescription]];
//            if (self.player.currentItem.error.code == -11839) {
                // 无法解码，解码器正忙
//                if (self.status == AFPlayerStatusPlay || self.status == AFPlayerStatusPrepareDone) {
//                    [self play];
//                }
//            }
            NSLog(@"-------------------------- 播放错误：%@  %@  %@--------------------------", self.url, self.player.error, self.player.currentItem.error);
            break;
            
        default:
            break;
    }
}


#pragma mark - 切换PlayerItem
- (void)replacePlayerItem:(AVPlayerItem *)item {
    
    if (item == self.player.currentItem) return;
    self.playerItem = item;
    
    if (self.player.currentItem) {
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
        NSLog(@"-------------------------- 来了11 --------------------------");
        self.playBtn.hidden = YES;
        [self replacePlayerItem:nil];
        return;
    } else {
        if (self.player.currentItem) {
            if (![self.url isEqualToString:[NSString stringWithFormat:@"file://%@", [AFDownloader filePathWithUrl:self.item.content]]]) {
                [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"数据错误, %@", self.displayDescription]];
                self.url = nil;
//                [self.player replaceCurrentItemWithPlayerItem:nil];
                [self replacePlayerItem:nil];
                self.coverImgView.image = nil;
                self.status = AFPlayerStatusNone;
            }
        }
    }
    
    switch (self.status) {
        case AFPlayerStatusPlay:
            [self startPlay];
            break;
            
        case AFPlayerStatusPrepare:
            [self startLoading];
            self.playBtn.hidden = YES;
            self.coverImgView.hidden = NO;
            NSLog(@"-------------------------- 来了22--------------------------");
            break;
            
        case AFPlayerStatusNone: {
            self.status = AFPlayerStatusPrepare;
            [self startLoading];
            self.playBtn.hidden = YES;
            self.coverImgView.image = nil;
            self.coverImgView.hidden = NO;
            NSLog(@"-------------------------- 来了33 --------------------------");
            if (self.player.currentItem) {
//                [self.player replaceCurrentItemWithPlayerItem:nil];
                [self replacePlayerItem:nil];
            }
            NSString *urlString = [self.item.content isKindOfClass:NSString.class] ? self.item.content : [(NSURL *)self.item.content absoluteString];
            if ([urlString containsString:@"file://"]) {
                self.url = urlString;
                [self attachCoverImage:self.item.coverImage];
                [self prepareDone];
                return;
            }
            [AFBrowserLoaderProxy loadVideo:urlString progress:nil completion:^(NSString *url, NSError *error) {
                if (error) {
                    NSLog(@"-------------------------- 下载错误：%@ --------------------------", error);
                } else {
                    if (![url isEqualToString:[NSString stringWithFormat:@"file://%@", [AFDownloader filePathWithUrl:self.item.content]]]) {
                        [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"URL已切换:%@, %@", url, self.displayDescription]];
                    } else if (url.length) {
                        self.url = url;
                        [self prepareDone];
                    } else {
                        [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"下载视频结果错误：url为空 , %@", self.displayDescription]];
                        NSLog(@"-------------------------- 下载视频结果错误：url为空 --------------------------");
                    }
                }
            }];
            [self attachCoverImage:self.item.coverImage];
        }
            break;
            
        default:
            break;
    }
}


#pragma mark - 准备完成
- (void)prepareDone {
//    [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"prepareDone数据准备完成, %@", self.displayDescription]];
    self.status = AFPlayerStatusPrepareDone;
    [self stopLoading];
    if (self.url.length) {
        if (!self.isActive) return;
//        [self.player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:[NSURL URLWithString:self.url]]];
        [self replacePlayerItem:[AVPlayerItem playerItemWithURL:[NSURL URLWithString:self.url]]];
//        self.progress = self.duration > 0 ? self.item.currentTime / self.duration : 0;
        [self seekToTime:self.item.currentTime];
        [self updateProgressWithCurrentTime:self.item.currentTime durationTime:self.duration];
//        [self updateProgressWithCurrentTime:0 durationTime:self.duration];
        if (self.playWhenPrepareDone) {
            // 准备完成，直接播放
            [self play];
            NSLog(@"-------------------------- 准备完成，调用play --------------------------");
        }
    } else {
        [self replacePlayerItem:nil];
        NSLog(@"-------------------------- 准备完成，url为空 --------------------------");
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
    self.status = AFPlayerStatusPlay;
    
    if (!self.item) {
        if (self.url) {
//            [self.player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:[NSURL URLWithString:self.url] ?: NSURL.new]];
            [self replacePlayerItem:[AVPlayerItem playerItemWithURL:[NSURL URLWithString:self.url]]];

        } else {
            [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"播放错误URL为空, %@", self.displayDescription]];
            NSLog(@"-------------------------- 播放错误：url为空 --------------------------");
        }
    }
    [self.player play];
    if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay || (self.player.currentItem.status == AVPlayerItemStatusUnknown && self.item.useCustomPlayer)) {
        if (self.item.showVideoControl) {
            self.bottomBar.playBtn.selected = YES;
        }
        self.coverImgView.hidden = YES;
        self.playBtn.hidden = YES;
        NSLog(@"-------------------------- 隐藏图片 --------------------------");
    }
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
    if (self.item.showVideoControl) {
        self.bottomBar.playBtn.selected = NO;
    }
    self.item.currentTime = self.progress * self.duration;
    self.status = AFPlayerStatusPause;
    self.playBtn.hidden = NO;
    [self.player pause];
    self.coverImgView.hidden = self.isActive ? self.progress < 1 : NO;
}


#pragma mark - 停止
- (void)stop {
//    [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"停止播放, %@", self.displayDescription]];
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
//    NSLog(@"-------------------------- stopPlay --------------------------");
    if (self.item.showVideoControl) {
        self.bottomBar.playBtn.selected = NO;
    }
    self.status = AFPlayerStatusStop;
    self.playBtn.hidden = NO;
    [self.player pause];
    self.coverImgView.hidden = NO;
    NSLog(@"-------------------------- 来了44 --------------------------");
    [self seekToTime:0.f];
}


#pragma mark - 播放结束
- (void)finishedPlay {
//    [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"播放结束 , %@", self.displayDescription]];
//    NSLog(@"-------------------------- finishedPlay --------------------------");
    if (self.item.showVideoControl) {
        self.bottomBar.playBtn.selected = NO;
    }
    self.status = AFPlayerStatusFinished;
    self.playBtn.hidden = NO;
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
- (void)updateProgressWithCurrentTime:(float)currentTime durationTime:(float)durationTime {
    if (self.item.showVideoControl) {
        [self.bottomBar updateProgressWithCurrentTime:currentTime durationTime:self.duration];
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
    [self.bottomBar updateProgressWithCurrentTime:sender.value * self.duration durationTime:self.duration];
}

- (void)sliderTouchUpAction:(UISlider *)sender{
    self.bottomBar.isSliderTouch = NO;
    if (self.status == AFPlayerStatusPlay && _AllPlayerSwitch) {
        [self.player play];
    }
}

- (void)slider:(AFPlayerSlider *)slider beginTouchWithValue:(float)value {
    [self.player pause];
    [self seekToTime:(value * self.duration)];
    [self.bottomBar updateProgressWithCurrentTime:value * self.duration durationTime:self.duration];
//    if (self.delegate && [self.delegate respondsToSelector:@selector(aliyunVodProgressView:dragProgressSliderValue:event:)]) {
//        [self.delegate aliyunVodProgressView:self dragProgressSliderValue:sliderValue event:UIControlEventTouchDownRepeat]; //实际是点击事件
//    }
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
    if (self.item.infiniteLoop) {
//                    weakSelf.progress = 0.f;
        [self seekToTime:0.f];
        [self play];
    } else {
        [self finishedPlay];
    }
}


#pragma mark - 收到通知：暂停所有正在播放的播放器
+ (void)pauseAllPlayer {
    _AllPlayerSwitch = NO;
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
    [NSNotificationCenter.defaultCenter postNotificationName:AFPlayerNotificationResumeAllPlayer object:nil];
}

- (void)resumeAllPlayerNotification {
    if (self.status == AFPlayerStatusPlay) {
        [self startPlay];
    }
}

@end
