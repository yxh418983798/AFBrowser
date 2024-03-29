//
//  AFBrowserTransformer.m
//  AFWorkSpace
//
//  Created by alfie on 2019/7/9.
//  Copyright © 2019 Alfie. All rights reserved.
//

#import "AFBrowserTransformer.h"
#import "AFBrowserItem.h"
#import "AFPlayerView.h"
#import "AFBrowserLoaderProxy.h"

@interface AFBrowserTransformer () <UIGestureRecognizerDelegate>

/** displayLink */
@property (strong, nonatomic) CADisplayLink   *displayLink;

/** 源控制器 */
@property (nonatomic, weak) UIViewController  *sourceVc;

/** 推出的控制器 */
@property (nonatomic, weak) UIViewController  *presentedVc;

/** 转场View */
@property (strong, nonatomic) UIView          *transitionView;

/** 转场View的父View */
@property (weak, nonatomic) UIView            *transitionSuperView;

/** 背景 */
@property (strong, nonatomic) UIView          *backGroundView;

/** presentedTrasitionView的原始frame */
@property (assign, nonatomic) CGRect          presentedTrasitionViewFrame;

/** 记录trasitionView的原始frame */
@property (assign, nonatomic) CGRect          trasitionViewOriginalFrame;

/** 图片转场，记录开始转场的frame，用于转场后意外情况的恢复 */
@property (assign, nonatomic) CGRect          imageBeginTransitionFrame;

/** 记录转场View的present前的frame */
@property (assign, nonatomic) CGRect          frameBeforePresent;

/** 记录转场view的dismiss前的frame */
@property (assign, nonatomic) CGRect          frameBeforeDismiss;

/** 浏览器imageView的高度 */
@property (assign, nonatomic) CGFloat         imgView_H;

/** 浏览器imageView的高度 */
@property (assign, nonatomic) CGFloat         progress;

/** 记录tag */
@property (nonatomic, assign) NSInteger       originalTag;

/** 是否手势交互 */
@property (assign, nonatomic) BOOL            isInteractive;

/** 是否取消转场 */
@property (assign, nonatomic) BOOL            isCancel;

/** 手势方向，是否从上往下 */
@property (assign, nonatomic) BOOL            isDirectionDown;

/** YES：prensent -- NO：dismiss */
@property (nonatomic, assign) BOOL            isPresenting;

/** 百分比控制 */
@property (nonatomic, strong) UIPercentDrivenInteractiveTransition *percentTransition;

/** player */
@property (nonatomic, weak) AFPlayerView      *player;

/** 异常情况下，重置下view */
@property (nonatomic, assign) BOOL            shouldReset;

@end


@implementation AFBrowserTransformer

#pragma mark - 生命周期
- (instancetype)init {
    if (self = [super init]) {
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationWillResignActiveNotification) name:UIApplicationWillResignActiveNotification object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void)dismiss {
    [self.presentedVc dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - APP非活跃状态的通知
- (void)applicationWillResignActiveNotification {
    // 进入后台，需要取消正常进行中的转场，避免View出现问题
    // 要在APP变成活跃的时候去设置isInteractive为NO，否则会和手势结束的方法冲突
    if (self.isInteractive) {
        [self.percentTransition finishInteractiveTransition];
    }
}

- (void)applicationDidBecomeActive {
    if (self.isInteractive) {
        self.isInteractive = NO;
    }
}


#pragma mark - 将转场的View的frame转化成屏幕上的frame
- (CGRect)transitionFrameWithView:(UIView *)transitionView {

    UIView *toView;
    for (UIView *view = transitionView; view; view = view.superview) {
        UIResponder *nextResponder = [view nextResponder];
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            toView = [(UIViewController *)nextResponder view].superview;
        }
    }
    if (!toView) toView = transitionView.window ?: UIApplication.sharedApplication.keyWindow;
    if (!toView) return CGRectZero;
    CGRect frame = [transitionView.superview convertRect:transitionView.frame toView:toView];
    if (frame.size.width < 1 || frame.size.height < 1) {
        [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"-------------------------- sourceFrame有问题，请检查代码 frame:%@  sourceView：%@--------------------------", NSStringFromCGRect(frame), transitionView]];
        frame = CGRectZero;
    }
    return frame;
}

- (UIView *)presentedTransitionView {
    AFBrowserItem *item = self.delegate.currentItem;
    if (item.type == AFBrowserItemTypeImage) {
        UIView *transitionView = [self.delegate transitionViewForPresentedController];
        if (!transitionView) {
            UIImageView *imageView = [[UIImageView alloc] initWithImage:UIImage.new];
            [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"-------------------------- presentedTransitionView是空的！请检查代码 --------------------------"]];
            return imageView;
        }
        return transitionView;
    } else {
        AFPlayerView *player = [self.delegate transitionViewForPresentedController];
        return player;
//        if (self.configuration.transitionStyle == AFBrowserTransitionStyleContinuousVideo) {
//            return [AFPlayerView playerWithItem:item configuration:self.configuration];
//        }
    }
}


#pragma mark - 转场时间
- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
//    return 4;
    return UINavigationControllerHideShowBarDuration;
}


#pragma mark - 自定义转场动画
- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    self.configuration.transitionStatus = AFTransitionStatusTransitioning;
//    NSLog(@"-------------------------- 设置：转场中 333 --------------------------");
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *fromView = fromVC.view;
    UIView *toView = toVC.view;
    //    UIView *fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
    //    UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    UIView *containerView = transitionContext.containerView;
    containerView.backgroundColor = UIColor.blackColor;
    
    if (self.isPresenting) {
        /// present
        [self presentWithAnimateTransition:transitionContext fromVC:fromVC toVC:toVC fromView:fromView toView:toView];
    } else {
        /// dismiss
        UIView *snapView;
        // iOS13以上添加toView的截图，13以下添加toView，不然会有bug
        if (@available(iOS 13.0, *)) {
            snapView = [toView snapshotViewAfterScreenUpdates:YES];
            snapView.frame = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height);
            [containerView addSubview:snapView];
        } else {
            toView.frame = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height);
            [containerView addSubview:toView];
            fromView.frame = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height);
            [containerView addSubview:fromView];
            snapView = [toView snapshotViewAfterScreenUpdates:YES];
            snapView.frame = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height);
            [containerView addSubview:snapView];
        }
        
        if (self.delegate.currentItem.type == AFBrowserItemTypeImage) {
            // 图片转场
            [self dismissImageWithAnimateTransition:transitionContext fromView:fromView toView:toView snapView:snapView];
        } else {
            // 视频转场
            [self dismissVideoWithAnimateTransition:transitionContext fromView:fromView toView:toView snapView:snapView];
        }
    }
}


#pragma mark - present转场动画
- (void)presentWithAnimateTransition:(id<UIViewControllerContextTransitioning>)transitionContext fromVC:(UIViewController *)fromVC toVC:(UIViewController *)toVC fromView:(UIView *)fromView toView:(UIView *)toView {
    UIView *containerView = transitionContext.containerView;
    UIView *transitionView = [self.delegate transitionViewForSourceController];
    CGRect transitionFrame = [self transitionFrameWithView:transitionView];
    UIView *presentedTransitionView;
    if (self.configuration.transitionStyle == AFBrowserTransitionStyleContinuousVideo && self.delegate.currentItem.type == AFBrowserItemTypeVideo) {
        self.player = transitionView;
        if (self.configuration.muteOption != AFPlayerMuteOptionAlways) {
//            NSLog(@"-------------------------- 设置静音NO --------------------------");
            self.player.muted = NO;
        }
    }

    // 添加交互手势
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];
    pan.delegate = self;
    if ([toVC isKindOfClass:[UINavigationController class]]) {
        [[[(UINavigationController *)toVC viewControllers].firstObject view] addGestureRecognizer:pan];
    } else {
        [toView addGestureRecognizer:pan];
    }
    
    // 如果 View为空 || frame有问题 || 定义了userDefaultAnimation，使用系统的默认转场
    if (!transitionView || CGRectEqualToRect(transitionFrame, CGRectZero) || self.configuration.transitionStyle == AFBrowserTransitionStyleSystem) {

        toView.frame = CGRectMake(0, UIScreen.mainScreen.bounds.size.height, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height);
        [containerView addSubview:toView];
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            toView.frame = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height);
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
        return;
    }
    
    // 使用自定义转场
    AFBrowserItem *item = self.delegate.currentItem;
    self.sourceVc = fromVC;
    self.presentedVc = toVC;
    toView.frame = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height);
    [containerView addSubview:toView];

    // 添加黑色背景
    [self addBackgroundViewToContainerView:containerView];
    
    CGSize imageSize;
    CGRect resultFrame;
    self.frameBeforePresent = transitionView.frame;
    // 拷贝一份用于转场的图片内容
    if (self.configuration.transitionStyle == AFBrowserTransitionStyleContinuousVideo) {
        self.transitionView = transitionView;
        self.originalTag = transitionView.tag;
        self.transitionSuperView = transitionView.superview;
        transitionView.frame = transitionFrame;
        self.trasitionViewOriginalFrame = transitionFrame;
        [containerView addSubview:transitionView];
        imageSize = [(AFPlayerView *)transitionView transitionSize];
        // 全屏自适应填充模式
        CGFloat height = UIScreen.mainScreen.bounds.size.height;
        resultFrame = UIScreen.mainScreen.bounds;
        // 计算比例填充
//        CGFloat height = UIScreen.mainScreen.bounds.size.width * fmax(imageSize.height, 1) / fmax(imageSize.width, 1);
//        height = fmin(height, UIScreen.mainScreen.bounds.size.height);
//        resultFrame = CGRectMake(0, fmax((UIScreen.mainScreen.bounds.size.height - height)/2, 0), UIScreen.mainScreen.bounds.size.width, height);
    } else {
        if (item.width > 0 && item.height > 0) {
            imageSize = CGSizeMake(item.width, item.height);
        }
        if ([transitionView isKindOfClass:UIImageView.class] && [(UIImageView *)transitionView image]) {
            UIImage *image = [(UIImageView *)transitionView image];
            if (CGSizeEqualToSize(imageSize, CGSizeZero)) imageSize = image.size;
            resultFrame = [AFBrowserTransformer displayFrameWithSize:image.size];
            if (resultFrame.size.height > UIScreen.mainScreen.bounds.size.height) {
                // 解决长图转场的过渡不自然的问题
                CGImageRef imageRef = image.CGImage;
                CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height * UIScreen.mainScreen.bounds.size.height / resultFrame.size.height);
                CGImageRef imageRefRect = CGImageCreateWithImageInRect(imageRef, rect);
                UIImage *newImage = [[UIImage alloc] initWithCGImage:imageRefRect];
                self.transitionView = [[UIImageView alloc] initWithImage:newImage];
                resultFrame.size.height = UIScreen.mainScreen.bounds.size.height;
                
            } else {
                self.transitionView = [[UIImageView alloc] initWithImage:image];
            }
            self.transitionView.clipsToBounds = YES;
            self.transitionView.contentMode = UIViewContentModeScaleAspectFill;
            self.transitionView.frame = transitionFrame;
        } else {
            UIImage *image = [self.delegate transitionImageForSourceController];
            if (image) {
                if (CGSizeEqualToSize(imageSize, CGSizeZero)) imageSize = image.size;
                self.transitionView = [[UIView alloc] initWithFrame:transitionFrame];
                self.transitionView.layer.contents = (__bridge id)image.CGImage;
                resultFrame = [AFBrowserTransformer displayFrameWithSize:image.size];
            } else {
                self.transitionView = [transitionView snapshotViewAfterScreenUpdates:NO];
                self.transitionView.frame = transitionFrame;
                if (CGSizeEqualToSize(imageSize, CGSizeZero)) imageSize = transitionView.frame.size;
                CGFloat height = UIScreen.mainScreen.bounds.size.width * fmax(imageSize.height, 1) / fmax(imageSize.width, 1);
                resultFrame = CGRectMake(0, fmax((UIScreen.mainScreen.bounds.size.height - height)/2, 0), UIScreen.mainScreen.bounds.size.width, height);
            }
        }
        if ([self.configuration.delegate respondsToSelector:@selector(browser:willDisplayImageContainView:forItemAtIndex:)]) {
            // 如果外部有实现自定义子视图代理方法，这里需要将子视图一起将入到转场
            [self.configuration.delegate browser:self.configuration.browserVc willDisplayImageContainView:self.transitionView forItemAtIndex:self.configuration.selectedIndex];
        }
        [containerView addSubview:self.transitionView];
        transitionView.hidden = YES;
    }
    
    // 执行动画
    [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{

        self.transitionView.frame = resultFrame;
        [self.transitionView layoutIfNeeded];
        self.backGroundView.alpha = 1;
        
    } completion:^(BOOL finished) {
        if (self.configuration.transitionStyle == AFBrowserTransitionStyleContinuousVideo) {
            if (!CGRectEqualToRect(self.transitionView.frame, UIScreen.mainScreen.bounds)) {
                self.transitionView.frame = UIScreen.mainScreen.bounds;
                [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"Present错误：resultFrame:%@, %@ --------------------------", NSStringFromCGRect(resultFrame), self.displayStatus]];
            }
        }
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        transitionView.hidden = NO;
        if ([transitionContext transitionWasCancelled]) {
            
            [self.backGroundView removeFromSuperview];
            [self.transitionView removeFromSuperview];
            self.backGroundView = nil;
            self.transitionView = nil;
            transitionView.frame = self.frameBeforePresent;
            [self.transitionSuperView addSubview:transitionView];
            [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"取消Present：%@ --------------------------", self.displayStatus]];
            
        } else {
            [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"完成Present：%@ --------------------------", self.displayStatus]];
            toView.hidden = NO;
            [self.backGroundView removeFromSuperview];
            if (self.configuration.transitionStyle != AFBrowserTransitionStyleContinuousVideo) {
                // 播放器不需要移除，在浏览器出现之后，这个播放器会自动添加到浏览器，如果移除了，可能会造成浏览器未加载完成时的黑屏
                [self.transitionView removeFromSuperview];
            }
            self.backGroundView = nil;
            self.transitionView = nil;
//            if (self.configuration.transitionStyle == AFBrowserTransitionStyleContinuousVideo) {
//                [[self.delegate superViewForTransitionView:transitionView] addSubview:transitionView];
//            }
        }
        self.configuration.transitionStatus = AFTransitionStatusPresented;
    }];
}


#pragma mark - dismiss图片的转场动画
- (void)dismissImageWithAnimateTransition:(id<UIViewControllerContextTransitioning>)transitionContext fromView:(UIView *)fromView toView:(UIView *)toView snapView:(UIView *)snapView {
    UIView *containerView = transitionContext.containerView;
    UIImageView *transitionView = (UIImageView *)self.presentedTransitionView;
    UIScrollView *scrollView = (UIScrollView *)transitionView.superview.superview;
    // 如果获取的transitionView为空 或 定义了userDefaultAnimation，使用系统的默认转场
    if (!scrollView || !transitionView || self.configuration.transitionStyle == AFBrowserTransitionStyleSystem) {
        fromView.frame = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height);
        [containerView addSubview:fromView];
//        NSLog(@"-------------------------- AFBrowser使用默认转场 \n scrollView:%@ \n  transitionView:%@ --------------------------", scrollView, transitionView);
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            fromView.frame = CGRectMake(0, UIScreen.mainScreen.bounds.size.height, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height);
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
            self.configuration.transitionStatus = AFTransitionStatusNormal;
        }];
        return;
    }
    
    // 获取转场的源视图
    UIView *sourceView = [self.delegate transitionViewForSourceController];
    CGRect sourceFrame = [self transitionFrameWithView:sourceView];
    if (CGRectIsEmpty(sourceFrame)) {
        NSLog(@"-------------------------- AFBrowser Dismiss图片sourceFrame为空 :%@ --------------------------", sourceView);
    }
    UIView *shadeView;
    if (self.configuration.hideSourceViewWhenTransition) {
        if (@available(iOS 13.0, *)) {
            shadeView = [[UIView alloc] initWithFrame:sourceFrame];
            shadeView.backgroundColor = UIColor.whiteColor;
            [containerView addSubview:shadeView];
        } else {
            sourceView.hidden = YES;
        }
    }

    // 添加黑色背景
    [self addBackgroundViewToContainerView:containerView];
    
    // 获取图片
//    self.transitionView = [transitionView snapshotViewAfterScreenUpdates:NO];
    self.transitionView = [[UIImageView alloc] initWithImage:transitionView.image];
    self.transitionView.contentMode = UIViewContentModeScaleAspectFill;
    self.transitionView.clipsToBounds = YES;
//    CGFloat height = scrollView.contentSize.height;
//    self.transitionView.frame = CGRectMake(-scrollView.contentOffset.x, fmax((UIScreen.mainScreen.bounds.size.height - height)/2, 0), scrollView.contentSize.width, scrollView.contentSize.height);
    if (transitionView.image) {
        self.transitionView.frame = [AFBrowserTransformer displayFrameWithSize:transitionView.image.size];
    } else {
        CGFloat height = UIScreen.mainScreen.bounds.size.width * fmax(transitionView.image.size.height, 1) / fmax(transitionView.image.size.width, 1);
        self.transitionView.frame = CGRectMake(0, fmax((UIScreen.mainScreen.bounds.size.height - height)/2, 0), UIScreen.mainScreen.bounds.size.width, height);
    }
    if ([self.configuration.delegate respondsToSelector:@selector(browser:willDisplayImageContainView:forItemAtIndex:)]) {
        // 如果外部有实现自定义子视图代理方法，这里需要将子视图一起将入到转场
        [self.configuration.delegate browser:self.configuration.browserVc willDisplayImageContainView:self.transitionView forItemAtIndex:self.configuration.selectedIndex];
    }
    self.presentedTrasitionViewFrame = self.transitionView.frame;
    if (!self.isInteractive) {
        // 处理长图收回去的不自然的效果，需要重新设置最大高度为屏幕高度
        if (self.transitionView.frame.size.height > UIScreen.mainScreen.bounds.size.height) {
            CGRect frame = self.transitionView.frame;
            frame.size.height = UIScreen.mainScreen.bounds.size.height;
            self.transitionView.frame = frame;
        }
    }
    [containerView addSubview:self.transitionView];
    fromView.hidden = YES;
    // 执行转场
    [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        
        if (AFBrowserConfiguration.isPortrait) {
            self.backGroundView.alpha = 0;
        }
        if (!self.isInteractive) {
            if (!sourceView || CGRectEqualToRect(sourceFrame, CGRectZero)) {
                // 如果获取到的转场视图为空，则使用淡入淡出的动画效果
                self.transitionView.alpha = 0;
            } else {
                // 使用位移的动画效果
                self.transitionView.frame = sourceFrame;
                [self.transitionView layoutIfNeeded];
            }
        }

    } completion:^(BOOL finished) {
        [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"即将完成DismissImage：%@ --------------------------", self.displayStatus]];
        self.presentedTransitionView.frame = self.imageBeginTransitionFrame;
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        sourceView.hidden = NO;
        [shadeView removeFromSuperview];
        if ([transitionContext transitionWasCancelled]) {
            [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"取消DismissImage：%@ --------------------------", self.displayStatus]];
            self.configuration.transitionStatus = AFTransitionStatusPresented;
            fromView.hidden = NO;
            [self.transitionView removeFromSuperview];
            [self.backGroundView removeFromSuperview];
            [snapView removeFromSuperview];
            self.backGroundView = nil;
            self.transitionView = nil;

        } else {
            self.configuration.transitionStatus = AFTransitionStatusNormal;
            [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"完成DismissImage：%@ --------------------------", self.displayStatus]];
            [self.transitionView removeFromSuperview];
            [self.backGroundView removeFromSuperview];
            [snapView removeFromSuperview];
            self.backGroundView = nil;
            self.transitionView = nil;
            if (self.shouldReset) {
                UIView *view = toView;
                while (view.superview) {
                    toView.frame = UIScreen.mainScreen.bounds;
                    view.transform = CGAffineTransformIdentity;
                    view = view.superview;
                }
                UIApplication.sharedApplication.delegate.window.frame = UIScreen.mainScreen.bounds;
                self.shouldReset = NO;
            }
        }
    }];
}


#pragma mark - dismiss视频的转场动画
- (void)dismissVideoWithAnimateTransition:(id<UIViewControllerContextTransitioning>)transitionContext fromView:(UIView *)fromView toView:(UIView *)toView snapView:(UIView *)snapView {
    
    UIView *containerView = transitionContext.containerView;
    UIView *transitionView = self.presentedTransitionView;
    AFBrowserItem *item = self.delegate.currentItem;

    // 如果获取的transitionView为空 或 定义了userDefaultAnimation，使用系统的默认转场
    if (!transitionView || self.configuration.transitionStyle == AFBrowserTransitionStyleSystem) {
        fromView.frame = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height);
        [containerView addSubview:fromView];
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            fromView.frame = CGRectMake(0, UIScreen.mainScreen.bounds.size.height, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height);
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
            self.configuration.transitionStatus = AFTransitionStatusNormal;
        }];
        return;
    }

    // 获取转场的源视图
    UIView *sourceView;
    CGRect sourceFrame;
    if (self.configuration.transitionStyle == AFBrowserTransitionStyleContinuousVideo) {
        sourceView = transitionView;
        sourceFrame = self.trasitionViewOriginalFrame;
    } else {
        sourceView = [self.delegate transitionViewForSourceController];
        sourceFrame = [self transitionFrameWithView:sourceView];
        sourceView.hidden = self.configuration.hideSourceViewWhenTransition;
    }

    if (CGRectIsEmpty(sourceFrame)) {
        NSLog(@"-------------------------- Dismiss 视频，sourceFrame为空 --------------------------");
    }
    // 添加黑色背景
    [self addBackgroundViewToContainerView:containerView];

    // 获取视频播放的容器
    self.transitionView = self.presentedTransitionView;
    UIView *superView = self.transitionView.superview;
    NSInteger index = [superView.subviews indexOfObject:self.transitionView];
    if (!self.isCancel) {
        self.presentedTrasitionViewFrame = self.transitionView.frame;
    } else {
        self.presentedTrasitionViewFrame = beginFrame;
    }
    [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"dismissVideo，设置presentedTrasitionViewFrame：%@", self.displayStatus]];
    // 将容器添加到containerView，保证转场过程中继续播放视频
//    [self.transitionView removeFromSuperview];
    [containerView addSubview:self.transitionView];
    fromView.hidden = YES;
    /// 当视频比例和外部的容器比例不一致的时候，计算出正确的最终的frame
    CGRect resultFrame = sourceFrame;
    self.player = (AFPlayerView *)self.transitionView;
    self.player.showVideoControl = NO;
    AVLayerVideoGravity gravity = self.player.videoGravity;
    if (!self.isInteractive && item.width > 0 && sourceFrame.size.width > 0 && item.height/item.width != sourceFrame.size.height/sourceFrame.size.width) {
        self.player.videoGravity = AVLayerVideoGravityResize;
        self.player.frame = self.playerFrame;
    }

    UIView *transitionSnapView;
    if (!self.isInteractive) {
        /// 非交互转场，直接拿图片过渡，不然效果不是很好
//        UIGraphicsBeginImageContextWithOptions(self.transitionView.bounds.size, self.transitionView.opaque, 0);
//        [self.transitionView drawViewHierarchyInRect:self.transitionView.bounds afterScreenUpdates:NO];
//        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
//        UIGraphicsEndImageContext();
//
//        transitionSnapView = [[UIImageView alloc] initWithImage:nil];
//        transitionSnapView.backgroundColor = UIColor.blueColor;
        transitionSnapView = [self.transitionView snapshotViewAfterScreenUpdates:NO];
        transitionSnapView.frame = self.transitionView.frame;
        [containerView addSubview:transitionSnapView];
        [self.transitionSuperView addSubview:self.transitionView];

    } else {
        transitionSnapView = self.transitionView;
    }
    
    // 执行转场动画
    [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        if (!self.isCancel && AFBrowserConfiguration.isPortrait) {
            self.backGroundView.alpha = 0;
        }
        if (!self.isInteractive) {
            if (!sourceView || CGRectEqualToRect(sourceFrame, CGRectZero)) {
                // 如果获取到的转场视图为空，则使用淡入淡出的动画效果
                self.transitionView.alpha = 0;
                [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"dismissVideo，淡入淡出:%@", self.displayStatus]];

            } else {
                // 使用位移的动画效果
                transitionSnapView.frame = self.isCancel ? self.presentedTrasitionViewFrame : sourceFrame;
                self.transitionView.frame = self.isCancel ? self.presentedTrasitionViewFrame : sourceFrame;
                if (CGRectEqualToRect(self.transitionView.frame, CGRectZero)) {
                    [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"dismissVideo错误，位移动画时frame为空！：%@", self.displayStatus]];
                } else {
                    [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"dismissVideo，位移动画！：%@", self.displayStatus]];
                }
            }
        }
        
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        sourceView.hidden = NO;
        [self.backGroundView removeFromSuperview];
        [snapView removeFromSuperview];
        if (transitionSnapView.superview) {
            [transitionSnapView removeFromSuperview];
        }
        self.transitionView.hidden = NO;
        self.player.videoGravity = gravity;
        if ([transitionContext transitionWasCancelled]) {
            self.configuration.transitionStatus = AFTransitionStatusPresented;
            [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"dismissVideo，completion取消转场！：%@", self.displayStatus]];
            fromView.hidden = NO;
            self.transitionView.frame = self.frameBeforeDismiss;
//            self.transitionView.frame = self.presentedTrasitionViewFrame;
            self.transitionView.alpha = 1;
            // 将视频播放容器 还原到转场后的容器
            [superView insertSubview:self.transitionView atIndex:index];
            if ([self.transitionView respondsToSelector:@selector(browserCancelDismiss)]) {
                [self.transitionView performSelector:@selector(browserCancelDismiss)];
            }
            self.player.showVideoControl = self.player.item.videoControlEnable; 
            [self.player browserCancelDismiss];
        } else {
            self.configuration.transitionStatus = AFTransitionStatusNormal;
            if (self.configuration.transitionStyle == AFBrowserTransitionStyleContinuousVideo) {
                if (self.configuration.muteOption != AFPlayerMuteOptionNever) {
                    self.player.muted = YES;
                }
                self.player.showVideoControl = NO;
                self.transitionView.tag = self.originalTag;
                if (self.transitionView.superview != self.transitionSuperView) {
                    [self.transitionSuperView addSubview:self.transitionView];
                }
            } else {
                if (self.transitionView.superview) {
                    [self.transitionView removeFromSuperview];
                }
            }
            self.transitionView.frame = self.frameBeforePresent;
//            NSLog(@"-------------------------- 完成了转场 --------------------------");
            UIViewController *browserVc = self.configuration.browserVc;
            if (browserVc.navigationController) {
                browserVc.navigationController.viewControllers = nil;
                [browserVc removeFromParentViewController];
            }
            [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"dismissVideo，completion完成转场！：%@", self.displayStatus]];
        }

        if (self.configuration.transitionStyle == AFBrowserTransitionStyleContinuousVideo) {
            if (([[[UIDevice currentDevice]systemVersion]floatValue] < 11.0)) {
                AVPlayer *player = [player valueForKey:@"_player"];
                [player play];
            }
        }
        self.isCancel = NO;
        self.transitionView = nil;
        self.backGroundView = nil;
    }];
}


#pragma mark - 添加黑色背景
- (void)addBackgroundViewToContainerView:(UIView *)containerView {
    self.backGroundView = [[UIView alloc] initWithFrame:(CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height))];
    self.backGroundView.backgroundColor = UIColor.blackColor;
    self.backGroundView.alpha = self.isPresenting ? 0 : 1;
    [containerView addSubview:self.backGroundView];
}


#pragma mark - UIViewControllerTransitioningDelegate
-(id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source{
    self.isPresenting = YES;
    self.sourceVc = source;
    self.presentedVc = presented;
    return self;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed{
    self.isPresenting = NO;
    self.presentedVc = dismissed;
    return self;
}

- (nullable id <UIViewControllerInteractiveTransitioning>)interactionControllerForPresentation:(id <UIViewControllerAnimatedTransitioning>)animator {
    return self.percentTransition;
}

- (nullable id <UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id <UIViewControllerAnimatedTransitioning>)animator {
    return self.percentTransition;
}


#pragma mark - 百分比手势的监听方法
static CGRect sourceFrame;
static CGRect beginFrame;

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)pan {
    if (self.delegate.currentItem.type == AFBrowserItemTypeCustomView) return NO;
    if (UIApplication.sharedApplication.applicationState != UIApplicationStateActive) {
        return NO;
    }
    if (![pan isKindOfClass:UIPanGestureRecognizer.class]) return YES;
    if (UIApplication.sharedApplication.statusBarOrientation != UIInterfaceOrientationPortrait) {
        [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"不是竖屏，过滤手势:%d",  UIApplication.sharedApplication.statusBarOrientation]];
        return NO;
    }
    
    CGPoint velocity = [pan velocityInView:pan.view];
//    NSLog(@"-------------------------- 打印：%@ -- %@ --------------------------", NSStringFromCGPoint(velocity), NSStringFromCGPoint([pan translationInView:pan.view]));
    if (fabs(velocity.x) > 0 && fabs(velocity.y / velocity.x) < 2) {
        return NO;
    }
    if (self.configuration.transitionStatus == AFTransitionStatusTransitioning) {
        [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"转场未结束，新手势事件过滤：%@", self.displayStatus]];
        return NO;
    }
    CGFloat systemVersion = UIDevice.currentDevice.systemVersion.floatValue;
    CGFloat velocityY = velocity.y;
    if (systemVersion < 12) {
        [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"轻扫:%g：%@", velocityY, self.displayStatus]];
        if (fabs(velocityY) > 1000) {
            [self.presentedVc dismissViewControllerAnimated:YES completion:nil];
            return NO;
        }
    }
    self.isDirectionDown = (velocityY > 0);
    return YES;
}

- (void)panAction:(UIScreenEdgePanGestureRecognizer *)pan {
    CGPoint point = [pan translationInView:[UIApplication sharedApplication].keyWindow];
    CGFloat progress = fabs(point.y / [UIApplication sharedApplication].keyWindow.bounds.size.height);
    progress = fmin(1, progress);
    self.progress = progress;

    switch (pan.state) {
        case UIGestureRecognizerStateBegan: {
            self.configuration.transitionStatus = AFTransitionStatusTransitioning;
            if (([[[UIDevice currentDevice]systemVersion]floatValue] < 11.0) && self.configuration.transitionStyle == AFBrowserTransitionStyleContinuousVideo) {
                AVPlayer *player = [self.player valueForKey:@"_player"];
                [player pause];
            }
            if (_displayLink) {
                [_displayLink invalidate];
                _displayLink = nil;
            }
            self.isInteractive = YES;
            self.isCancel = NO;
            self.percentTransition = [[UIPercentDrivenInteractiveTransition alloc] init];
            [self.presentedVc dismissViewControllerAnimated:YES completion:nil];
            self.transitionView = self.presentedTransitionView;
            if (CGRectEqualToRect(self.frameBeforeDismiss, CGRectZero)) {
                self.frameBeforeDismiss = self.transitionView.frame;
            }
            AFBrowserItem *item = self.delegate.currentItem;
            if (item.type == AFBrowserItemTypeImage) {
                self.imageBeginTransitionFrame = self.transitionView.frame;
                UIImageView *transitionView  = (UIImageView *)self.presentedTransitionView;
                NSAssert(transitionView, @"transitionView为空！");
                self.imgView_H = UIScreen.mainScreen.bounds.size.width * fmax(transitionView.image.size.height, 1) / fmax(transitionView.image.size.width, 1);
                beginFrame = self.transitionView.superview.frame;
            } else {
//                self.transitionView = self.presentedTransitionView;
                NSAssert(self.transitionView, @"transitionView为空！");
                self.imgView_H = self.transitionView.frame.size.height;
                beginFrame = self.transitionView.frame;
            }
            sourceFrame = self.configuration.transitionStyle == AFBrowserTransitionStyleContinuousVideo ? self.trasitionViewOriginalFrame : [self transitionFrameWithView:[self.delegate transitionViewForSourceController]];
            if (CGRectIsEmpty(sourceFrame)) {
            }
            self.trasitionViewOriginalFrame = sourceFrame;
            [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"startPan开始手势：%@", self.displayStatus]];
        }
            break;
            
        case UIGestureRecognizerStateChanged: {
            if (AFBrowserConfiguration.isPortrait) {
                self.backGroundView.alpha = fmax(1-progress*3, 0);
            }
            CGFloat original_Y;
            CGFloat distance_W = (beginFrame.size.width - sourceFrame.size.width) * progress;
            CGFloat current_W = beginFrame.size.width - distance_W;
            CGFloat scale = beginFrame.size.width > 0 ? current_W / beginFrame.size.width : 0;
            if (self.isDirectionDown) {
                if (self.imgView_H > UIScreen.mainScreen.bounds.size.height) {
                    original_Y = 0;
                } else {
                    original_Y = (UIScreen.mainScreen.bounds.size.height - self.imgView_H)/2;
                }
                self.transitionView.frame = CGRectMake(distance_W/2 + point.x + beginFrame.origin.x, original_Y + point.y, current_W, self.imgView_H * scale);
            } else {
                if (self.imgView_H > UIScreen.mainScreen.bounds.size.height) {
                    original_Y = (UIScreen.mainScreen.bounds.size.height - self.imgView_H);
                } else {
                    original_Y = (UIScreen.mainScreen.bounds.size.height - self.imgView_H)/2;
                }
                CGFloat height = self.imgView_H * scale;
                self.transitionView.frame = CGRectMake(distance_W/2 + point.x + beginFrame.origin.x, original_Y + point.y + (self.imgView_H - height), current_W, height);
            }
            [self.percentTransition updateInteractiveTransition:progress];
        }
            break;
            
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded: {
            if (!self.isInteractive) {
                if (self.configuration.transitionStatus == AFTransitionStatusTransitioning) {
                    self.configuration.transitionStatus = AFTransitionStatusPresented;
                }
                return;
            }
            self.isInteractive = NO;
            AFBrowserItem *item = self.delegate.currentItem;
            if (item.type == AFBrowserItemTypeImage && UIApplication.sharedApplication.applicationState != UIApplicationStateActive) {
                self.backGroundView.alpha = 0;
                if ((CGRectEqualToRect(sourceFrame, CGRectZero) || ![self.delegate transitionViewForSourceController] && !self.configuration.transitionStyle == AFBrowserTransitionStyleContinuousVideo)) {
                    // 如果获取到的转场视图为空，则使用淡入淡出的动画效果
                    self.transitionView.alpha = 0;
                } else {
                    // 使用位移的动画效果
                    self.transitionView.frame = sourceFrame;
                }
                self.configuration.transitionStatus = AFTransitionStatusNormal;
                [self.percentTransition finishInteractiveTransition];
                self.percentTransition = nil;
                return;
            }
            if(progress > 0.15){
                if (item.type == AFBrowserItemTypeImage && (UIDevice.currentDevice.systemVersion.floatValue >= 11.0)) {
                    if (self.transitionView.frame.size.height > UIScreen.mainScreen.bounds.size.height) {
                        CGRect frame = self.transitionView.frame;
                        frame.size.height = UIScreen.mainScreen.bounds.size.height;
                        if (isnan(frame.origin.y)) frame.origin.y = 0;
                        self.transitionView.frame = frame;
                    }
                    [UIView animateWithDuration:[self transitionDuration:nil] delay:0 usingSpringWithDamping:1 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseIn animations:^{
                        self.backGroundView.alpha = 0;
                        if ((CGRectEqualToRect(sourceFrame, CGRectZero) || ![self.delegate transitionViewForSourceController] && !self.configuration.transitionStyle == AFBrowserTransitionStyleContinuousVideo)) {
                            // 如果获取到的转场视图为空，则使用淡入淡出的动画效果
                            self.transitionView.alpha = 0;
                        } else {
                            // 使用位移的动画效果
                            self.transitionView.frame = sourceFrame;
                            [self.transitionView layoutIfNeeded];
                        }
                    } completion:^(BOOL finished) {
//                        NSLog(@"-------------------------- AFBrowser 图片手势结束，自动完成转场 --------------------------");
                        self.configuration.transitionStatus = AFTransitionStatusNormal;
                        [self.percentTransition finishInteractiveTransition];
                        self.percentTransition = nil;
                    }];
                } else {
                    if ([self.transitionView isKindOfClass:AFPlayerView.class]) {
                        AFPlayerView *player = (AFPlayerView *)self.transitionView;
                        if (item.width > 0 && sourceFrame.size.width > 0 && item.height/item.width != sourceFrame.size.height/sourceFrame.size.width) {
                            player.videoGravity = AVLayerVideoGravityResize;
                            CGRect frame = self.playerFrame;
                            frame.origin.y = player.frame.origin.y + fabs((player.frame.size.height - frame.size.height)/2);
                            frame.origin.x = player.frame.origin.x;
                            player.frame = frame;
                        }
                    }
                    [self.displayLink addToRunLoop:NSRunLoop.currentRunLoop forMode:NSRunLoopCommonModes];
                }
                [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"endPan完成手势：%@", self.displayStatus]];
            } else {
//                NSLog(@"-------------------------- AFBrowser 图片手势结束，自动取消转场 --------------------------");
                self.configuration.transitionStatus = AFTransitionStatusPresented;
                [self cancelInteractiveTransition];
            }
        }
            break;
            
        default:
            if (self.configuration.transitionStatus == AFTransitionStatusTransitioning) {
                self.configuration.transitionStatus = AFTransitionStatusPresented;
//                NSLog(@"-------------------------- 设置：Presented 333 --------------------------");
            }
            break;
    }
}

- (void)startInteractiveTransition:(nonnull id<UIViewControllerContextTransitioning>)transitionContext {}


#pragma mark - 取消转场
- (void)cancelInteractiveTransition {
    self.isCancel = YES;
    AFBrowserItem *item = self.delegate.currentItem;
    if (item.type == AFBrowserItemTypeImage) {
        if (UIDevice.currentDevice.systemVersion.floatValue >= 11.0) {
            [self animationCancel];
        } else {
            [self displayLinkCancel];
        }
    } else {
        [self displayLinkCancel];
//        if (UIDevice.currentDevice.systemVersion.floatValue >= 12.0) {
//            [self displayLinkCancel];
//        } else {
//            [self animationCancel];
//        }
    }
}

- (void)animationCancel {
    self.backGroundView.alpha = 1;
    self.presentedTrasitionViewFrame = beginFrame;
    CGRect resultFrame = beginFrame; /// 避免beginFrame在下次的手势中被修改，这里要拷贝一个新的frame
    [UIView animateWithDuration:[self transitionDuration:nil] delay:0 usingSpringWithDamping:1 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.transitionView.frame = resultFrame;
    } completion:^(BOOL finished) {
        [self.percentTransition cancelInteractiveTransition];
        self.percentTransition = nil;
    }];
    [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"[animationCancel]endPan取消手势：%@", self.displayStatus]];
}

- (void)displayLinkCancel {
    [self.displayLink addToRunLoop:NSRunLoop.currentRunLoop forMode:NSRunLoopCommonModes];
    [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"[displayLinkCancel]endPan取消手势：%@", self.displayStatus]];
}


#pragma mark - 计算图片 展示的frame
static CGFloat ScaleDistance = 0.4;
+ (CGRect)displayFrameWithSize:(CGSize)size {
    
    // 如果图片自适应屏幕宽度后得到的高度 大于 屏幕高度，设置高度为自适应高度
    CGRect frame = UIScreen.mainScreen.bounds; // 初始frame
    CGRect resultFrame = frame;
    BOOL isPortrait = UIScreen.mainScreen.bounds.size.height > UIScreen.mainScreen.bounds.size.width; // 是否竖屏
    CGFloat portraitW = fmin(frame.size.height, frame.size.width); // 竖屏下的宽度
    CGFloat portraitH = fmax(frame.size.height, frame.size.width); // 竖屏下的高度
    CGFloat portraitScale = portraitH/portraitW; // 竖屏下的高宽比
    CGFloat scale = size.height / size.width; // 图片的高宽比
    BOOL isFitHeight = NO; // 记录是否自适应高度
    if (scale - portraitScale > ScaleDistance) {
        // 如果图片的比例 - 屏幕的比例 > 限制的差距，代表这张图是比较长的长图，此时要自适应高度
        isFitHeight = YES;
    } else {
        if (isPortrait) {
            // 如果图片的高宽比例 <= 屏幕的高宽比例 && 竖屏，此时要自适应高度
            if (scale <= portraitScale) isFitHeight = YES;
        } else {
            // 如果图片的宽高比例 > 屏幕的宽高比例 && 横屏，此时要自适应高度
            if (1/scale > (portraitScale)) isFitHeight = YES;
        }
    }
    
    if (isFitHeight) {
        // 自适应高度
        CGFloat height = floor(scale * (isPortrait ? portraitW : portraitH)); // 向下取整
        if (height < 1 || isnan(height)) height = frame.size.height;
        height = floor(height);
        resultFrame.size.height = height;
        if (isPortrait) {
            if (height < portraitH) {
                resultFrame.origin.y = (frame.size.height - resultFrame.size.height)/2;
            }
        } else {
            if (height < portraitW) {
                resultFrame.origin.x = (frame.size.width - resultFrame.size.width)/2;
            }
        }
    } else {
        // 如果图片的比例 > 屏幕的比例 且 不超过限制差距，代表这张图不是很长的的长图，此时要自适应宽度
        CGFloat width = floor((isPortrait ? portraitH : portraitW) / scale);
        if (width < 1 || isnan(width)) width = frame.size.width;
        width = floor(width);
        resultFrame.size.width = width;
        if (resultFrame.size.height > frame.size.height) {
            resultFrame.size.height = frame.size.height;
        }
        if (isPortrait) {
            resultFrame.origin.x = (frame.size.width - resultFrame.size.width)/2;
        } else {
            resultFrame.origin.y = (frame.size.height - resultFrame.size.height)/2;
        }
    }
    return resultFrame;
}

/// 定时器
- (CADisplayLink *)displayLink {
    if (!_displayLink) {
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(timerAction)];
        _displayLink.frameInterval = 1;
    }
    return _displayLink;
}


- (void)timerAction {
    
    CGFloat number = [self transitionDuration:nil] * 60; // 0.25 * 60
    static CGFloat distance;
    static CGFloat x;
    static CGFloat y;
    static CGFloat w;
    static CGFloat h;
    CGRect resultFrame;
    CGFloat progress;
    CGRect currentFrame = self.transitionView.frame;
    if (self.isCancel) {
        // 取消转场
        progress = self.progress;
        self.progress -= distance;
        if (self.progress < 0) self.progress = 0.f;
        resultFrame = beginFrame;
    } else {
        // 继续完成转场
        progress = 1 - self.progress;
        self.progress += distance;
        if (self.progress > 1) self.progress = 1;
        resultFrame = sourceFrame;
    }
//    NSLog(@"-------------------------- progress:%g --------------------------", self.progress);
    if (distance == 0) distance = progress/number;
    if (x == 0) x = (resultFrame.origin.x - currentFrame.origin.x)/number;
    if (y == 0) y = (resultFrame.origin.y - currentFrame.origin.y)/number;
    if (w == 0) w = (resultFrame.size.width - currentFrame.size.width)/number;
    if (h == 0) h = (resultFrame.size.height - currentFrame.size.height)/number;
    [self.percentTransition updateInteractiveTransition:self.progress];
    self.backGroundView.alpha = progress;
    if (!self.isCancel && ![self.delegate transitionViewForSourceController] && self.configuration.transitionStyle != AFBrowserTransitionStyleContinuousVideo) {
        // 如果获取到的转场视图为空，则使用淡入淡出的动画效果
        self.transitionView.alpha = progress;
    } else {
        // 使用位移的动画效果
        self.transitionView.frame = CGRectMake(currentFrame.origin.x + x, currentFrame.origin.y + y, currentFrame.size.width + w, currentFrame.size.height + h);
    }
    
    if (self.progress >= 1 || self.progress <= 0) {
        x = y = w = h = distance = 0;
        [_displayLink invalidate];
        _displayLink = nil;
        self.transitionView.frame = self.isCancel ? beginFrame : sourceFrame;
        [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"timerAction结束：%@", self.displayStatus]];
        if (self.isCancel) {
            self.backGroundView.alpha = 1;
            self.configuration.transitionStatus = AFTransitionStatusPresented;
//            NSLog(@"-------------------------- 设置：Presented 444 --------------------------");
            [self.percentTransition cancelInteractiveTransition];
        } else {
            self.backGroundView.alpha = 0;
            self.configuration.transitionStatus = AFTransitionStatusNormal;
//            NSLog(@"-------------------------- 设置：Normal 333 --------------------------");
            [self.percentTransition finishInteractiveTransition];
        }
        self.percentTransition = nil;
    }
}


- (CGRect)playerFrame {
    CGRect resultFrame = UIScreen.mainScreen.bounds;
    AFBrowserItem *item = self.delegate.currentItem;
    CGFloat scale = item.height/item.width;
    CGFloat screenScale = resultFrame.size.height/resultFrame.size.width;
    if (screenScale < 1) screenScale = 1.f/screenScale; // 横屏的情况
    if (scale > screenScale) {
        // 视频的比例超出的屏幕的比例，此时应该自适应宽度，高度为屏幕高度
        CGFloat width = resultFrame.size.height / scale;
        resultFrame.origin.x = (resultFrame.size.width - width) /2;
        resultFrame.size.width = width;
    } else {
        // 视频的比例未超出屏幕的比例，此时应该自适应高度，宽度为屏幕宽度
        CGFloat height = scale * resultFrame.size.width;
        resultFrame.origin.y = (resultFrame.size.height - height) /2;
        resultFrame.size.height = height;
    }
    [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"计算playerFrame：%@ , %@", NSStringFromCGRect(resultFrame), self.displayStatus]];
    return resultFrame;
}


- (NSString *)displayStatus {
    return [NSString stringWithFormat:@"状态描述：self.transitionView：%@ \n superView:%：%@\n sourceFrame：%@ \n presentedTrasitionViewFrame:%@ \n beginFrame:%@, frameBeforePresent:%@, frameBeforeDismiss:%@ \n isCancel:%d", self.transitionView, self.transitionView.superview, NSStringFromCGRect(sourceFrame), NSStringFromCGRect(self.presentedTrasitionViewFrame), NSStringFromCGRect(beginFrame), NSStringFromCGRect(self.frameBeforePresent), NSStringFromCGRect(self.frameBeforeDismiss), self.isCancel];
}

@end
