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

/** url */
@property (strong, nonatomic) AFBrowserItem         *currentItem;

/** 准备完成后是否自动播放，默认No */
@property (assign, nonatomic) BOOL          playWhenPrepareDone;

/** 监听进度对象 */
@property (strong, nonatomic) id            playerObserver;

/** 记录进度 */
@property (assign, nonatomic) CGFloat       progress;

/** 记录时长 */
@property (assign, nonatomic) float         duration;

/** 记录是否在监听 */
@property (nonatomic, assign) BOOL          isObserving;

/** 播放的url */
@property (nonatomic, copy) NSString        *url;

@end


@implementation AFPlayer

static NSString * const AFPlayerNotificationPauseAllPlayer = @"AFPlayerNotificationPauseAllPlayer";
static NSString * const AFPlayerNotificationResumeAllPlayer = @"AFPlayerNotificationResumeAllPlayer";
static BOOL _AllPlayerSwitch = YES; // 记录播放器总开关


#pragma mark - 生命周期
+ (void)initialize {
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(resumeAllPlayer) name:UIApplicationWillEnterForegroundNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(pauseAllPlayer) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(pauseAllPlayerNotification) name:AFPlayerNotificationPauseAllPlayer object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(resumeAllPlayerNotification) name:AFPlayerNotificationResumeAllPlayer object:nil];
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
    if (self.currentItem.showVideoControl) {
        [self.contentView addSubview:self.dismissBtn];
        [self addSubview:self.bottomBar];
    }
//    NSLog(@"-------------------------- didMoveToSuperview:%@ --------------------------", self.superview);
}

- (void)layoutSubviews {
    [CATransaction begin];
    [CATransaction setAnimationDuration:0];
    [CATransaction setDisableActions:YES];
    self.playerLayer.frame = self.bounds;
    [CATransaction commit];
    CGFloat size = 50.f;
    self.contentView.frame = self.bounds;
    self.coverImgView.frame = self.bounds;
    self.playBtn.frame = CGRectMake((self.frame.size.width - size)/2, (self.frame.size.height - size)/2, size, size);
    self.activityView.frame = CGRectMake((self.frame.size.width - size)/2, (self.frame.size.height - size)/2, size, size);
    if (self.currentItem.showVideoControl) {
        self.dismissBtn.frame = CGRectMake(0, UIApplication.sharedApplication.statusBarFrame.size.height == 44 ? 44 : 20, 50, 44);
        self.bottomBar.frame = CGRectMake(0, self.frame.size.height - 80, self.frame.size.width, 50);
    }
    [super layoutSubviews];
}

- (void)dealloc {
//    NSLog(@"-------------------------- 哈哈释放了播放器 --------------------------");
    [self observePlayerTime:NO];
    [self observeItemStatus:NO];
    [_player replaceCurrentItemWithPlayerItem:nil];
    [_playerLayer removeFromSuperlayer];
    _player = nil;
    _playerLayer = nil;
}


// 控制器即将销毁，做一些转场动画的处理
- (void)browserWillDismiss {
    if (self.currentItem.showVideoControl) {
        self.bottomBar.alpha = 0;
        self.dismissBtn.alpha = 0;
    }
//    self.playBtn.hidden = YES;
//    [self stopLoading];
}

/// 控制器取消Dismiss，做一些恢复处理
- (void)browserCancelDismiss {
    self.showToolBar = self.showToolBar;
//    self.playBtn.hidden = self.isPlaying;
//    if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
//        self.coverImgView.hidden = YES;
//        [self stopLoading];
//    } else {
//        self.coverImgView.hidden = NO;
//        [self startLoading];
//    }
}


#pragma mark - setter
- (void)setItem:(AFBrowserItem *)item {
    if (!_item || _item.content != item.content) {
        _item = item;
        self.playWhenPrepareDone = NO;
        if (_item.showVideoControl && _bottomBar.superview) [self addSubview:self.bottomBar];
        self.status = AFPlayerStatusNone;
    }
}

- (void)setShowToolBar:(BOOL)showToolBar {
    _showToolBar = showToolBar;
    if (self.currentItem.showVideoControl) {
        self.bottomBar.alpha = _showToolBar ? 1 : 0;
        self.dismissBtn.alpha = _showToolBar ? 1 : 0;
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
        [_playBtn addTarget:self action:@selector(play) forControlEvents:(UIControlEventTouchUpInside)];
    }
    return _playBtn;
}

- (UIButton *)dismissBtn {
    if (!_dismissBtn) {
        _dismissBtn = [UIButton new];
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
        _playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
//        _playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        _playerLayer.masksToBounds= YES;
    }
    return _playerLayer;
}

- (AFPlayerBottomBar *)bottomBar {
    if (!_bottomBar) {
        _bottomBar = [AFPlayerBottomBar new];
        _bottomBar.slider.delegate = self;
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

- (CGSize)transitionSize {
    if (self.currentItem.width > 0 && self.currentItem.height > 0) {
        return CGSizeMake(self.currentItem.width, self.currentItem.height);
    }
    if (self.coverImgView.image) {
        return self.coverImgView.image.size;
    }
    return self.frame.size;
}

/// 开始加载动画
- (void)startLoading {
    [self.activityView startAnimating];
}

/// 结束加载动画
- (void)stopLoading {
    [self.activityView stopAnimating];
}


#pragma mark - 准备播放
- (void)prepare {
    if (!self.item.content) {
        [self stopLoading];
        [self attachCoverImage:self.item.coverImage];
        self.coverImgView.hidden = NO;
        self.playBtn.hidden = YES;
        [self observeItemStatus:NO];
        [self observePlayerTime:NO];
        return;
    }
    switch (self.status) {
        case AFPlayerStatusPlay:
            [self startPlay];
            break;
            
        case AFPlayerStatusPrepare:
            [self startLoading];
            self.playBtn.hidden = YES;
            self.coverImgView.hidden = NO;
            break;
            
        case AFPlayerStatusNone: {
            self.status = AFPlayerStatusPrepare;
            [self startLoading];
            self.playBtn.hidden = YES;
            self.coverImgView.hidden = NO;
            NSString *urlString = [self.item.content isKindOfClass:NSString.class] ? self.item.content : [(NSURL *)self.item.content absoluteString];
            [AFBrowserLoaderProxy loadVideo:urlString progress:nil completion:^(NSString *url, NSError *error) {
                if (error) {
                    NSLog(@"-------------------------- 下载错误：%@ --------------------------", error);
                } else {
                    if (!url.length) {
                        NSLog(@"-------------------------- 下载视频结果错误：url为空 --------------------------");
                    } else {
                        self.url = url;
                        [self prepareDone];
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
    
    self.status = AFPlayerStatusPrepareDone;
    [self observeItemStatus:NO];
//    [self.player replaceCurrentItemWithPlayerItem:nil];
    
//    if (self.player.currentItem) {
//        if (self.currentItem == self.item) return;
//        [self observeItemStatus:NO];
//    }
    self.currentItem = self.item;
    [self stopLoading];
    self.progress = 0.f;
    if (self.url.length) {
        [self.player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:[NSURL URLWithString:self.url]]];
        [self observeItemStatus:YES];
        [self updateProgressWithCurrentTime:0.f durationTime:self.duration];
        if (self.playWhenPrepareDone) {
            // 准备完成，直接播放
            [self play];
        }
    } else {
        [self.player replaceCurrentItemWithPlayerItem:nil];
        NSLog(@"-------------------------- 准备完成，url为空 --------------------------");
    }
}


#pragma mark - 播放
- (void)play {
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
    self.coverImgView.hidden = YES;
    self.playBtn.hidden = YES;
    
    if (!self.currentItem) {
        if (self.url) {
            [self.player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:[NSURL URLWithString:self.url] ?: NSURL.new]];
        } else {
            NSLog(@"-------------------------- 播放错误：url为空 --------------------------");
        }
    }
    [self observeItemStatus:YES];
    [self observePlayerTime:YES];
    [self.player play];
    if (self.currentItem.showVideoControl) {
        self.bottomBar.playBtn.selected = YES;
    }
}

/// 点击播放/暂停按钮
- (void)playBtnAction:(UIButton *)playBtn {
    playBtn.selected ? [self pause] : [self play];
}


#pragma mark - 暂停
- (void)pause {
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
    if (self.currentItem.showVideoControl) {
        self.bottomBar.playBtn.selected = NO;
    }
    self.status = AFPlayerStatusPause;
    self.playBtn.hidden = NO;
    [self.player pause];
    self.coverImgView.hidden = self.progress < 1;
    [self observeItemStatus:NO];
    [self observePlayerTime:NO];
}


#pragma mark - 停止
- (void)stop {
    
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
        [self observeItemStatus:NO];
    }
//    if (self.playerObserver) {
//        [self.player removeTimeObserver:self.playerObserver];
//        self.playerObserver = nil;
//    }
    [self.player replaceCurrentItemWithPlayerItem:nil];
}

/// 停止播放
- (void)stopPlay {
//    NSLog(@"-------------------------- stopPlay --------------------------");
    if (self.currentItem.showVideoControl) {
        self.bottomBar.playBtn.selected = NO;
    }
    self.status = AFPlayerStatusStop;
    self.playBtn.hidden = NO;
    [self.player pause];
    [self observeItemStatus:NO];
    self.coverImgView.hidden = NO;
    [self seekToTime:0.f];
    [self observeItemStatus:NO];
    [self observePlayerTime:NO];
//    [self.player replaceCurrentItemWithPlayerItem:nil];
}


#pragma mark - 播放结束
- (void)finishedPlay {
//    NSLog(@"-------------------------- finishedPlay --------------------------");
    if (self.currentItem.showVideoControl) {
        self.bottomBar.playBtn.selected = NO;
    }
    self.status = AFPlayerStatusFinished;
    self.playBtn.hidden = NO;
    [self.player pause];
    self.coverImgView.hidden = self.progress < 1;
}


#pragma mark - 跳转
- (void)seekToTime:(NSTimeInterval)time {
    [self.player seekToTime:CMTimeMakeWithSeconds(time, self.player.currentItem.asset.duration.timescale) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}


- (float)duration {
    if (self.currentItem.duration > 0) {
        return self.currentItem.duration;
    } else {
        return CMTimeGetSeconds(self.player.currentItem.duration);
    }
}


#pragma mark - 更新bottomBar的进度
- (void)updateProgressWithCurrentTime:(float)currentTime durationTime:(float)durationTime {
    if (self.currentItem.showVideoControl) {
        [self.bottomBar updateProgressWithCurrentTime:currentTime durationTime:self.duration];
    } else {
        if (_bottomBar.superview) [_bottomBar removeFromSuperview];
        _bottomBar = nil;
    }
}


#pragma mark - KVO
/// 监听播放器状态
- (void)observeItemStatus:(BOOL)isAdd {

    if (isAdd) {
        if (self.isObserving) return;
        self.isObserving = YES;
        [self.player.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    } else {
        if (self.isObserving) {
            self.isObserving = NO;
            [self.player.currentItem removeObserver:self forKeyPath:@"status"];
        }
    }
}

/// 监听播放进度
- (void)observePlayerTime:(BOOL)isAdd {

    if (isAdd) {
        if (!self.playerObserver) {
            __weak typeof(self) weakSelf = self;
            self.playerObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(0.5, NSEC_PER_SEC) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
                weakSelf.progress = CMTimeGetSeconds(time) / weakSelf.duration;
//                NSLog(@"-------------------------- progress：%g--------------------------", weakSelf.progress);
                if (isnan(weakSelf.progress)) {
                    weakSelf.progress = 0;
                }
                [weakSelf updateProgressWithCurrentTime:CMTimeGetSeconds(time) durationTime:weakSelf.duration];
                if (weakSelf.progress >= 1.0) {
                    weakSelf.status = AFPlayerStatusFinished;
                    // 播放结束
                    if ([weakSelf.delegate respondsToSelector:@selector(finishWithPlayer:)]) {
                        [weakSelf.delegate finishWithPlayer:weakSelf];
                    }
                    if (weakSelf.currentItem.infiniteLoop) {
    //                    weakSelf.progress = 0.f;
                        [weakSelf seekToTime:0.f];
                        [weakSelf play];
                    } else {
                        [weakSelf finishedPlay];
                    }
                }
            }];
        }
    } else {
        if (self.playerObserver) {
            [self.player removeTimeObserver:self.playerObserver];
            self.playerObserver = nil;
        }
    }
}

/// 监听回调
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"status"]) {
        switch (self.player.currentItem.status) {
                
            case AVPlayerItemStatusReadyToPlay:
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
                NSLog(@"-------------------------- 播放错误：%@  %@  %@--------------------------", self.url, self.player.error, self.player.currentItem.error);
                break;
                
            default:
                break;
        }
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
    if (self.status == AFPlayerStatusPlay) {
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


#pragma mark - 暂停所有正在播放的播放器
+ (void)pauseAllPlayer {
    _AllPlayerSwitch = NO;
    [NSNotificationCenter.defaultCenter postNotificationName:AFPlayerNotificationPauseAllPlayer object:nil];
}

- (void)pauseAllPlayerNotification {
    if (self.status == AFPlayerStatusPlay) {
        [self pausePlay];
        self.status = AFPlayerStatusPlay;
    }
}


#pragma mark - 恢复所有播放器的状态，如果暂停前是正在播放的，会继续播放
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
