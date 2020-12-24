//
//  AFBrowserCollectionViewCell.m
//  AFWorkSpace
//
//  Created by alfie on 2019/7/9.
//  Copyright © 2019 Alfie. All rights reserved.
//

#import "AFBrowserCollectionViewCell.h"
#import "AFBrowserItem.h"
#import "AFBrowserConfiguration.h"
#import "AFBrowserLoaderProxy.h"
#import <YYImage/YYImage.h>
#import "AFBrowserEnum.h"
#import <SDWebImage/SDWebImage.h>

@interface AFBrowserScrollView: UIScrollView
@end

@implementation AFBrowserScrollView
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer == self.panGestureRecognizer) {
        CGPoint point = [self.panGestureRecognizer translationInView:self];
        if (self.contentOffset.y <= 0 && point.y > 0) {
            return point.y < fabs(point.x);
        } else if (self.contentOffset.y + self.frame.size.height >= self.contentSize.height && point.y < 0) {
            return fabs(point.y) < fabs(point.x);
        }
    }
    return YES;
}
@end


@interface AFBrowserCollectionViewCell () <UIScrollViewDelegate, UIGestureRecognizerDelegate, AFPlayerDelegate>

/** 图片容器 */
@property (nonatomic, strong) UIView                 *imageContainerView;

/** item */
@property (strong, nonatomic) AFBrowserItem          *item;

/** 配置 */
@property (nonatomic, strong) AFBrowserConfiguration *configuration;

/** 记录indexPath */
@property (strong, nonatomic) NSIndexPath            *indexPath;

/** 记录状态 */
@property (assign, nonatomic) AFLoadImageStatus      loadImageStatus;

/** 下载原图 */
@property (nonatomic, strong) UIButton               *loadOriginalImgBtn;

/** 长按手势 */
@property (nonatomic, strong) UILongPressGestureRecognizer   *longPressGestureRecognizer;

@end


static CGFloat MinScaleDistance = 0.4;
static CGFloat MaxScaleDistance = 3.f;

@implementation AFBrowserCollectionViewCell

#pragma mark - 生命周期
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
        _scrollView = [[AFBrowserScrollView alloc] init];
        if (@available(iOS 11.0, *)) {
            _scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        _scrollView.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height);
        _scrollView.bouncesZoom = YES;
        _scrollView.maximumZoomScale = 3;
        _scrollView.minimumZoomScale = 1.0;
        _scrollView.multipleTouchEnabled = YES;
        _scrollView.delegate = self;
        _scrollView.scrollsToTop = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _scrollView.delaysContentTouches = NO;
        _scrollView.canCancelContentTouches = YES;
        _scrollView.alwaysBounceVertical = NO;
        [self addSubview:_scrollView];
        
        _imageContainerView = [[UIView alloc] init];
        _imageContainerView.clipsToBounds = YES;
//        _imageContainerView.contentMode = UIViewContentModeScaleAspectFit;
        [_scrollView addSubview:_imageContainerView];
        
        _imageView = [[YYAnimatedImageView alloc] init];
        //        _imageView.backgroundColor = [UIColor colorWithWhite:1.000 alpha:0.5];
//        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        _imageView.clipsToBounds = YES;
        [_imageContainerView addSubview:_imageView];

        
        UITapGestureRecognizer *tap1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
        [self addGestureRecognizer:tap1];
        UITapGestureRecognizer *tap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
        tap2.numberOfTapsRequired = 2;
        [tap1 requireGestureRecognizerToFail:tap2];
        [self addGestureRecognizer:tap2];
        self.longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
        [self addGestureRecognizer:self.longPressGestureRecognizer];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateVideoStatus:) name:@"AFBrowserUpdateVideoStatus" object:nil];
    }
    return self;
}


#pragma mark - UI
- (AFPlayer *)player {
    if (!_player) {
        _player = [AFPlayer playerWithItem:self.item configuration:self.configuration];
        for (UIGestureRecognizer *gestureRecognizer in _player.gestureRecognizers) {
            if ([gestureRecognizer isKindOfClass:UILongPressGestureRecognizer.class]) {
                [gestureRecognizer requireGestureRecognizerToFail:self.longPressGestureRecognizer];
                break;
            }
        }
    }
    return _player;
}

- (UIButton *)loadOriginalImgBtn {
    if (!_loadOriginalImgBtn) {
        _loadOriginalImgBtn = UIButton.new;
        _loadOriginalImgBtn.frame = CGRectMake(UIScreen.mainScreen.bounds.size.width/2 - 60, UIScreen.mainScreen.bounds.size.height - 65, 120, 35);
        _loadOriginalImgBtn.layer.cornerRadius = 5.f;
        _loadOriginalImgBtn.layer.masksToBounds = YES;
        _loadOriginalImgBtn.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];
        [_loadOriginalImgBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        [_loadOriginalImgBtn addTarget:self action:@selector(downloadOriginImage) forControlEvents:UIControlEventTouchUpInside];
        _loadOriginalImgBtn.titleLabel.font = [UIFont systemFontOfSize:14.0];
    }
    return _loadOriginalImgBtn;
}

//- (void)layoutSubviews {
//    [super layoutSubviews];
//    NSLog(@"-------------------------- layoutSubviews --------------------------");
//    [self resizeSubviewSize];
//}

/// 是否显示查看原图的按钮
- (void)showLoadOriginalImgBtn:(BOOL)show {
    if (show) {
        NSString *sizeStr = @"";
        if (self.item.size > 0) {
            CGFloat size = self.item.size/1024.0;
            if (size > 1000.0) {
                sizeStr = [NSString stringWithFormat:@"(%.1fM)",size/1024.0];
            } else {
                sizeStr = [NSString stringWithFormat:@"(%.0fK)",size];
            }
        }
        NSString *title = [NSString stringWithFormat:@"%@%@", [AFBrowserLoaderProxy localizedString:@"查看原图"], sizeStr];
        CGFloat btn_W = [title boundingRectWithSize:(CGSizeMake(MAXFLOAT, 35)) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:14]} context:nil].size.width + 20;
        self.loadOriginalImgBtn.frame = CGRectMake((UIScreen.mainScreen.bounds.size.width - btn_W)/2, UIScreen.mainScreen.bounds.size.height - 65, btn_W, 35);
        [self.loadOriginalImgBtn setTitle:title forState:(UIControlStateNormal)];
        [self addSubview:self.loadOriginalImgBtn];
    } else {
        if (_loadOriginalImgBtn.superview) {
            [_loadOriginalImgBtn removeFromSuperview];
            _loadOriginalImgBtn = nil;
        }
    }
}

/// 显示图片
- (void)displayImageItem:(AFBrowserItem *)item {
    if (_player.superview) {
        [_player removeFromSuperview];
        _player = nil;
    }
    [_scrollView setZoomScale:1.0];
    
    // 获取原图缓存
    UIImage *originalImage = [self.delegate browserCell:self hasImageCache:item.content atIndex:self.indexPath.row];
    if (originalImage) {
        // 已经下载过原图，直接显示
        self.imageView.image = originalImage;
        self.loadImageStatus = AFLoadImageStatusOriginal;
        [self showLoadOriginalImgBtn:NO];
        [self resizeSubviewSize];
        return;
    }
    
    // 获取缩略图缓存
    UIImage *coverImage = [self.delegate browserCell:self hasImageCache:item.coverImage atIndex:self.indexPath.row];
    if (coverImage) {
        // 缓存中有缩略图，直接展示
        if (self.loadImageStatus == AFLoadImageStatusNone) {
            self.loadImageStatus = AFLoadImageStatusCover;
            self.imageView.image = coverImage;
            [self resizeSubviewSize];
        }
    } else {
        // 缩略图也没有，先展示占位图
        self.imageView.image = AFBrowserLoaderProxy.placeholderImageForBrowser;
        if (item.coverImage) {
            if ([item.coverImage isKindOfClass:NSString.class]) {
                [AFBrowserLoaderProxy loadImage:[NSURL URLWithString:item.coverImage] completion:^(UIImage *image, NSError *error) {
                    if (self.loadImageStatus == AFLoadImageStatusNone && image) {
                        if (item.content != self.item.content) {
                            [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"AFBrowser加载图片错误！，item.content:%@ \n self.item.content:%@", item.content, self.item.content]];
                        } else {
                            self.loadImageStatus = AFLoadImageStatusCover;
                            self.imageView.image = image;
                            [self resizeSubviewSize];
                        }
                    } else {
                        if (error) {
                            [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"AFBrowser加载图片失败！，status:%d, error:%@ \n item.content:%@ \n self.item.content:%@", self.loadImageStatus, error, item.content, self.item.content]];
                        }
                    }
                }];
            } else if ([item.coverImage isKindOfClass:NSURL.class]) {
                [AFBrowserLoaderProxy loadImage:item.coverImage completion:^(UIImage *image, NSError *error) {
                    if (self.loadImageStatus == AFLoadImageStatusNone && image) {
                        self.loadImageStatus = AFLoadImageStatusCover;
                        self.imageView.image = image;
                        [self resizeSubviewSize];
                    }
                }];
            } else if ([item.coverImage isKindOfClass:UIImage.class])  {
                if (self.loadImageStatus == AFLoadImageStatusNone) {
                    self.loadImageStatus = AFLoadImageStatusCover;
                    self.imageView.image = item.coverImage;
                    [self resizeSubviewSize];
                }
            }
        }
    }
    if ([self.delegate browserCell:self shouldAutoLoadOriginalImageForItemAtIndex:self.indexPath.row]) {
        // 显示原图按钮，此时不需要下载原图，等待用户手动触发
        [self showLoadOriginalImgBtn:YES];
    } else {
        // 不显示原图，则直接自动下载原图，下载完后直接展示
        [self showLoadOriginalImgBtn:NO];
        if ([item.content isKindOfClass:NSString.class]) {
            [AFBrowserLoaderProxy loadImage:[NSURL URLWithString:item.content] completion:^(UIImage *image, NSError *error) {
                if (error) {
                    [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"AFBrowser加载图片失败！，status:%d, error:%@ \n item.content:%@ \n self.item.content:%@", self.loadImageStatus, error, item.content, self.item.content]];
                    return;
                }
                if (item.content != self.item.content) {
                    [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"AFBrowser加载图片错误！，item.content:%@ \n self.item.content:%@", item.content, self.item.content]];
                } else {
                    self.imageView.image = image;
                    self.loadImageStatus = AFLoadImageStatusOriginal;
                    [self resizeSubviewSize];
                }
            }];
        } else if ([item.content isKindOfClass:NSURL.class]) {
            [AFBrowserLoaderProxy loadImage:item.content completion:^(UIImage *image, NSError *error) {
                self.imageView.image = image;
                self.loadImageStatus = AFLoadImageStatusOriginal;
                [self resizeSubviewSize];
            }];
        } else if ([item.content isKindOfClass:UIImage.class])  {
            self.loadImageStatus = AFLoadImageStatusOriginal;
            self.imageView.image = item.content;
            [self resizeSubviewSize];
            //设置缩放比例为适应屏幕高度
            //    self.scrollView.maximumZoomScale = HScreen_Height/(HScreen_Width * image.size.height/image.size.width);
        } else {
            self.loadImageStatus = AFLoadImageStatusOriginal;
            self.imageView.image = [UIImage new];
            [self resizeSubviewSize];
        }
    }
}


#pragma mark - 更新布局
- (void)resizeSubviewSize {
    
    //视频
    if (self.item.type == AFBrowserItemTypeVideo) {
        _scrollView.hidden = YES;
        self.player.frame = UIScreen.mainScreen.bounds;
        [self addSubview:self.player];
//        self.player.hidden = NO;
    }
    
    //图片
    else {
        if (_player) {
            [_player removeFromSuperview];
            _player = nil;
        }
        if (_loadOriginalImgBtn) {
            CGFloat btn_W = self.loadOriginalImgBtn.frame.size.width;
            self.loadOriginalImgBtn.frame = CGRectMake((UIScreen.mainScreen.bounds.size.width - btn_W)/2, UIScreen.mainScreen.bounds.size.height - 65, btn_W, 35);
        }
//        [_player pause];
//        _player.hidden = YES;
        _scrollView.hidden = NO;
        _imageContainerView.frame = CGRectMake(0, 0, _scrollView.frame.size.width, _scrollView.frame.size.height);
        UIImage *image = _imageView.image;
        // 如果图片自适应屏幕宽度后得到的高度 大于 屏幕高度，设置高度为自适应高度
        CGRect frame = _imageContainerView.frame;
        BOOL isPortrait = UIScreen.mainScreen.bounds.size.height > UIScreen.mainScreen.bounds.size.width; // 是否竖屏
        CGFloat portraitW = fmin(_scrollView.frame.size.height, _scrollView.frame.size.width);
        CGFloat portraitH = fmax(_scrollView.frame.size.height, _scrollView.frame.size.width);
        CGFloat portraitScale = portraitH/portraitW;
        CGFloat imageScale = image.size.height / image.size.width;

        AFImageSizeType sizeType = AFImageSizeTypeNormal;
        AFImageAdjustType adjustType = AFImageAdjustTypeHeight;
        
        /// 竖屏
        if (isPortrait) {
            if (imageScale - portraitScale > MinScaleDistance) {
                // 如果图片的比例 - 竖屏幕的比例 > 限制的差距，代表这张图是比较长的长图，此时要自适应高度
                sizeType = AFImageSizeTypeLongLong;
                adjustType = AFImageAdjustTypeHeight;
            } else {
                // 如果图片的高宽比例 <= 竖屏幕的高宽比例，代表正常图，此时要自适应高度
                if (imageScale <= portraitScale) {
                    sizeType = AFImageSizeTypeNormal;
                    adjustType = AFImageAdjustTypeHeight;
                } else {
                    // 不是很长的长图，直接固定屏幕高度，自适应宽度
                    sizeType = AFImageSizeTypeLong;
                    adjustType = AFImageAdjustTypeWidth;
                }
            }
        }
        
        /// 横屏
        else {
            CGFloat shortDistance = imageScale - 1/portraitScale;
            CGFloat scaleDistance = imageScale - portraitScale;
            // 如果图片的高宽比例 <= 横屏幕的高宽比例，代表短图，此时自适应高度
            if (shortDistance <= 0) {
                sizeType = AFImageSizeTypeShort;
                adjustType = AFImageAdjustTypeHeight;
            } else {
                CGFloat distance = scaleDistance - MinScaleDistance;
                if (distance > 0) {
                    // 比较长的长图，计算出一个合适的宽高比例
                    sizeType = AFImageSizeTypeLongLong;
                    CGFloat minW = portraitW * portraitW / portraitH; // 最小宽度
                    frame.size.width = minW + (portraitH - minW) * (fmin(MaxScaleDistance, distance)/MaxScaleDistance);
                    adjustType = AFImageAdjustTypeSize;
                } else {
                    // 不是很长的长图或正常图，直接固定屏幕高度，自适应宽度
                    sizeType = AFImageSizeTypeLong;
                    adjustType = AFImageAdjustTypeWidth;
                }
            }
        }
        
//        if (imageScale - portraitScale > ScaleDistance) {
//            // 如果图片的比例 - 屏幕的比例 > 限制的差距，代表这张图是比较长的长图，此时要自适应高度
//            isFitHeight = YES;
//        } else {
//            if (isPortrait) {
//                // 如果图片的高宽比例 <= 屏幕的高宽比例 && 竖屏，此时要自适应高度
//                if (imageScale <= portraitScale) isFitHeight = YES;
//            } else {
//                // 如果图片的宽高比例 > 屏幕的宽高比例 && 横屏，此时要自适应高度
//                if (1/imageScale > (portraitScale)) isFitHeight = YES;
//            }
//        }
        
        switch (adjustType) {
            case AFImageAdjustTypeHeight: {
                // 自适应高度
                CGFloat height = floor(imageScale * (isPortrait ? portraitW : portraitH)); // 向下取整
                if (height < 1 || isnan(height)) height = _scrollView.frame.size.height;
                height = floor(height);
                frame.size.height = height;
                _imageContainerView.frame = frame;
                CGPoint center = _imageContainerView.center;
                center.x = _scrollView.frame.size.width / 2;
                if (isPortrait) {
                    if (height < portraitH) {
                        center.y = _scrollView.frame.size.height / 2;
                    }
                } else {
                    if (height < portraitW) {
                        center.y = _scrollView.frame.size.height / 2;
                    }
                }
                _imageContainerView.center = center;
            }
                break;
                
            case AFImageAdjustTypeWidth: {
                // 如果图片的比例 > 屏幕的比例 且 不超过限制差距，代表这张图不是很长的的长图，此时要自适应宽度
    //            CGFloat width = floor((isPortrait ? portraitH : portraitW) / imageScale);
                CGFloat width = floor(frame.size.height / imageScale);
                if (width < 1 || isnan(width)) width = _scrollView.frame.size.width;
                width = floor(width);
                frame.size.width = width;
                _imageContainerView.frame = frame;
                
                if (_imageContainerView.frame.size.height > _scrollView.frame.size.height) {
                    frame.size.height = _scrollView.frame.size.height;
                    _imageContainerView.frame = frame;
                }
                CGPoint center = _imageContainerView.center;
                center.x = _scrollView.frame.size.width / 2;
                if (isPortrait) {

                } else {
                    center.y = _scrollView.frame.size.height / 2;
                }
                _imageContainerView.center = center;
            }
                break;
                
            default: {
                // 自适应高度
                CGFloat height = floor(imageScale * frame.size.width); // 向下取整
                if (height < 1 || isnan(height)) height = _scrollView.frame.size.height;
                height = floor(height);
                frame.size.height = height;
                _imageContainerView.frame = frame;
                CGPoint center = _imageContainerView.center;
                center.x = _scrollView.frame.size.width / 2;
                if (isPortrait) {
                    if (height < portraitH) {
                        center.y = _scrollView.frame.size.height / 2;
                    }
                } else {
                    if (height < portraitW) {
                        center.y = _scrollView.frame.size.height / 2;
                    }
                }
                _imageContainerView.center = center;
            }
                break;
        }

        _scrollView.contentSize = CGSizeMake(_scrollView.frame.size.width, MAX(_imageContainerView.frame.size.height, _scrollView.frame.size.height));
        [_scrollView scrollRectToVisible:_scrollView.bounds animated:NO];
        
        // 如果高度小于屏幕高度，关闭反弹
        if (_imageContainerView.frame.size.height <= _scrollView.frame.size.height) {
            _scrollView.alwaysBounceVertical = NO;
        } else {
            _scrollView.alwaysBounceVertical = YES;
        }
        
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        _imageView.frame = _imageContainerView.bounds;
        [CATransaction commit];
    }
}


#pragma mark - 绑定数据
- (void)attachItem:(AFBrowserItem *)item configuration:(AFBrowserConfiguration *)configuration atIndexPath:(NSIndexPath *)indexPath {

    self.configuration = configuration;
    self.item = item;
    self.indexPath = indexPath;
    self.loadImageStatus = AFLoadImageStatusNone;
//http://dl2.weshineapp.com/gif/20201104/8bfa369267398b699c4b4b474b638f1b.jpg?v=5fa2d00190770&f=mowang
    switch (item.type) {
        case AFBrowserItemTypeImage: {
            [self displayImageItem:item];
        }
            break;
            
        case AFBrowserItemTypeVideo: {
            self.player.item = item;
            self.player.transitionStatus = AFPlayerTransitionStatusFullScreen;
            self.player.browserDelegate = self;
            [self.player prepare];
            [self resizeSubviewSize];
        }
            break;
    }
}


#pragma mark - UIScrollViewDelegate
//返回一个允许缩放的视图
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _imageContainerView;
}

//缩放时调用，更新布局，视图顶格贴边展示
- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    
    UIView *subView = _imageContainerView;
    CGFloat offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width) ? (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5 : 0.0;
    CGFloat offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height) ? (scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5 : 0.0;
    subView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX, scrollView.contentSize.height * 0.5 + offsetY);
}


#pragma mark - 滑动时 更新视频状态
- (void)updateVideoStatus:(NSNotification *)notification {
    
    if (self.item.type != AFBrowserItemTypeVideo) return;

    // 播放视频
    if ([@(self.indexPath.item) isEqualToNumber:notification.object]) {
        if (self.item.autoPlay) {
            [self.player play];
            if (self.configuration.playOption == AFBrowserPlayOptionNeverAutoPlay) {
                self.item.autoPlay = NO;
            }
        }
    }
    
    // 暂停视频
    else {
        [self.player pause];
        [self.player seekToTime:0.f];
    }
}


- (void)stopPlayer {
    [_player pause];
}


/// 重置下自定义视图
- (void)removeCustomView {
    for (UIView *subView in self.subviews) {
        if (subView == _scrollView || subView == _player) continue;
        [subView removeFromSuperview];
    }
}


#pragma mark - AFPlayerDelegate
/// 点击cell
- (void)tapActionInPlayer:(AFPlayer *)player {
    if ([self.delegate respondsToSelector:@selector(singleTapAction)]) {
        [self.delegate singleTapAction];
    }
}

/// dismissPlayer的回调
- (void)dismissActionInPlayer:(AFPlayer *)player {
    if ([self.delegate respondsToSelector:@selector(dismissActionAtCollectionViewCell:)]) {
        [self.delegate dismissActionAtCollectionViewCell:self];
    }
}


#pragma mark - 单击手势
- (void)singleTap:(UITapGestureRecognizer *)tap {
    if ([self.delegate respondsToSelector:@selector(singleTapAction)]) {
        [self.delegate singleTapAction];
    }
}


#pragma mark - 双击手势
- (void)doubleTap:(UITapGestureRecognizer *)tap {
    if (_scrollView.zoomScale > 1.0) {
        [_scrollView setZoomScale:1.0 animated:YES];
    } else {

        CGPoint touchPoint = [tap locationInView:_imageView];
        CGFloat newZoomScale = _scrollView.maximumZoomScale;
        CGFloat xsize = [[UIScreen mainScreen] bounds].size.width / newZoomScale;
        CGFloat ysize = [[UIScreen mainScreen] bounds].size.height / newZoomScale;
        [_scrollView zoomToRect:CGRectMake(touchPoint.x - xsize/2, touchPoint.y - ysize/2, xsize, ysize) animated:YES];
    }
}


#pragma mark - 长按事件
- (void)longPressAction:(UILongPressGestureRecognizer *)longPress {
    if (_player.isSliderTouch) return;
    switch (longPress.state) {
        case UIGestureRecognizerStateBegan:
            if ([self.delegate respondsToSelector:@selector(longPressActionAtCollectionViewCell:)]) {
                [self.delegate longPressActionAtCollectionViewCell:self];
            }
            break;
            
        default:
            break;
    }
}


#pragma mark - 下载原图
- (void)downloadOriginImage {
    _loadOriginalImgBtn.userInteractionEnabled = NO;
    [SDWebImageManager.sharedManager loadImageWithURL:self.item.content options:SDWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
        double progress = ((double)receivedSize/(double)(expectedSize))*100;
        if (progress > 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.loadOriginalImgBtn setTitle:[NSString stringWithFormat:@"%.0f%%", progress] forState:UIControlStateNormal];
            });
        }
    } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        
//        self.aiView.hidden = YES;
//        [self.aiView stopAnimating];
        if ([self.configuration.delegate respondsToSelector:@selector(browser:didCompletedDownloadOriginalImageItem:error:)]) {
            [self.configuration.delegate browser:self.delegate didCompletedDownloadOriginalImageItem:self.item error:error];
        }
        if(error){
            [self.loadOriginalImgBtn setTitle:@"下载失败，重新下载" forState:(UIControlStateNormal)];
            self.loadOriginalImgBtn.userInteractionEnabled = YES;
        } else {
            if (_loadOriginalImgBtn) {
                [_loadOriginalImgBtn removeFromSuperview];
                _loadOriginalImgBtn = nil;
            }
            self.imageView.image = image;
        }
    }];
}

@end


