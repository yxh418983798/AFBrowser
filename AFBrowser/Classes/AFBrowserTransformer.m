//
//  AFBrowserTransformer.m
//  AFWorkSpace
//
//  Created by alfie on 2019/7/9.
//  Copyright © 2019 Alfie. All rights reserved.
//

#import "AFBrowserTransformer.h"
#import "AFBrowserItem.h"
#import "AFPlayer.h"

@interface AFBrowserTransformer ()

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

/** 记录trasitionView的原始frame */
@property (assign, nonatomic) CGRect          originalFrameForTrasitionSuperView;

/** 浏览器imageView的高度 */
@property (assign, nonatomic) CGFloat         imgView_H;

/** 记录tag */
@property (nonatomic, assign) NSInteger       originalTag;

/** 是否手势交互 */
@property (assign, nonatomic) BOOL            isInteractive;

/** 手势方向，是否从上往下 */
@property (assign, nonatomic) BOOL            isDirectionDown;

/** YES：prensent -- NO：dismiss */
@property (nonatomic, assign) BOOL            isPresenting;

/** 百分比控制 */
@property (nonatomic, strong) UIPercentDrivenInteractiveTransition *percentTransition;

@end



@implementation AFBrowserTransformer

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
        NSLog(@"-------------------------- sourceFrame有问题，请检查代码 frame:%@  sourceView：%@--------------------------", NSStringFromCGRect(frame), transitionView);
        frame = CGRectZero;
    }
    return frame;
}

- (UIView *)presentedTransitionView {
    UIView *transitionView = [self.delegate transitionViewForPresentedController];
    if (!transitionView && self.item.type == AFBrowserItemTypeImage) {
        UIImageView *imageView = [UIImageView new];
        imageView.image = [UIImage new];
        NSLog(@"-------------------------- presentedTransitionView是空的！请检查代码 --------------------------");
        return imageView;
    }
    return transitionView;
}


#pragma mark - dismiss
- (void)dismiss {
    [self.presentedVc dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - 转场时间
- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.4;
}


#pragma mark - 自定义转场动画
- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *fromView = fromVC.view;
    UIView *toView = toVC.view;
    //    UIView *fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
    //    UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    UIView *containerView = transitionContext.containerView;
    containerView.backgroundColor = UIColor.whiteColor;
    
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
        }
        
        if (self.item.type == AFBrowserItemTypeImage) {
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
    if (self.item.useCustomPlayer && self.item.type == AFBrowserItemTypeVideo) {
        self.item.player = transitionView;
        self.item.player.muted = NO;
    }

    // 添加交互手势
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];
    if ([toVC isKindOfClass:[UINavigationController class]]) {
        [[[(UINavigationController *)toVC viewControllers].firstObject view] addGestureRecognizer:pan];
    } else {
        [toView addGestureRecognizer:pan];
    }
    
    // 如果 View为空 || frame有问题 || 定义了userDefaultAnimation，使用系统的默认转场
    if (!transitionView || CGRectEqualToRect(transitionFrame, CGRectZero) || self.userDefaultAnimation) {

        toView.frame = CGRectMake(0, UIScreen.mainScreen.bounds.size.height, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height);
        [containerView addSubview:toView];
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            toView.frame = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height);
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
        return;
    }
    
    // 使用自定义转场
    self.sourceVc = fromVC;
    self.presentedVc = toVC;
    toView.frame = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height);
//    toView.hidden = YES;
    [containerView addSubview:toView];

    // 添加黑色背景
    [self addBackgroundViewToContainerView:containerView];
    
    CGSize imageSize;
    CGRect resultFrame;
    CGRect originalFrame = transitionView.frame;
    // 拷贝一份用于转场的图片内容
    if (self.item.useCustomPlayer) {
        self.transitionView = transitionView;
        self.originalTag = transitionView.tag;
        self.originalFrameForTrasitionSuperView = transitionView.frame;
        self.transitionSuperView = transitionView.superview;
//        [transitionView removeFromSuperview];
        transitionView.frame = transitionFrame;
        [containerView addSubview:transitionView];
//        NSLog(@"-------------------------- 设置了frame --------------------------");
        imageSize = [(AFPlayer *)transitionView transitionSize];
        self.trasitionViewOriginalFrame = transitionFrame;
        CGFloat height = UIScreen.mainScreen.bounds.size.width * fmax(imageSize.height, 1) / fmax(imageSize.width, 1);
        height = fmin(height, UIScreen.mainScreen.bounds.size.height);
        resultFrame = CGRectMake(0, fmax((UIScreen.mainScreen.bounds.size.height - height)/2, 0), UIScreen.mainScreen.bounds.size.width, height);
    } else {
        if ([transitionView isKindOfClass:UIImageView.class] && [(UIImageView *)transitionView image]) {
            UIImage *image = [(UIImageView *)transitionView image];
            self.transitionView = [[UIView alloc] initWithFrame:transitionFrame];
            self.transitionView.layer.contents = (__bridge id)image.CGImage;
            resultFrame = [AFBrowserTransformer displayFrameWithSize:image.size];
        } else {
            self.transitionView = [transitionView snapshotViewAfterScreenUpdates:NO];
            self.transitionView.frame = transitionFrame;
            CGFloat height = UIScreen.mainScreen.bounds.size.width * fmax(imageSize.height, 1) / fmax(imageSize.width, 1);
            resultFrame = CGRectMake(0, fmax((UIScreen.mainScreen.bounds.size.height - height)/2, 0), UIScreen.mainScreen.bounds.size.width, height);
        }
        if (CGSizeEqualToSize(imageSize, CGSizeZero)) imageSize = transitionView.frame.size;
        [containerView addSubview:self.transitionView];
        transitionView.hidden = YES;
    }
    
    // 执行动画
    [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{

        self.transitionView.frame = resultFrame;
        self.backGroundView.alpha = 1;
        
    } completion:^(BOOL finished) {
//        NSLog(@"-------------------------- 即将完成转场 --------------------------");
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        transitionView.hidden = NO;
        if ([transitionContext transitionWasCancelled]) {
            
            [self.backGroundView removeFromSuperview];
            [self.transitionView removeFromSuperview];
            self.backGroundView = nil;
            self.transitionView = nil;
            
            transitionView.frame = originalFrame;
            [self.transitionSuperView addSubview:transitionView];
            
        } else {
//            NSLog(@"-------------------------- 完成转场 --------------------------");
            [NSNotificationCenter.defaultCenter postNotificationName:@"AFBrowserFinishedTransaction" object:nil];
            toView.hidden = NO;
            [self.backGroundView removeFromSuperview];
            [self.transitionView removeFromSuperview];
            self.backGroundView = nil;
            self.transitionView = nil;
            if (self.item.useCustomPlayer) {
                [[self.delegate superViewForTransitionView:transitionView] addSubview:transitionView];
            }
        }
    }];
}


#pragma mark - dismiss图片的转场动画
- (void)dismissImageWithAnimateTransition:(id<UIViewControllerContextTransitioning>)transitionContext fromView:(UIView *)fromView toView:(UIView *)toView snapView:(UIView *)snapView {

    UIView *containerView = transitionContext.containerView;
    UIImageView *transitionView = (UIImageView *)self.presentedTransitionView;
    UIScrollView *scrollView = (UIScrollView *)transitionView.superview.superview;
    // 如果获取的transitionView为空 或 定义了userDefaultAnimation，使用系统的默认转场
    if (!scrollView || !transitionView || self.userDefaultAnimation) {
        fromView.frame = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height);
        [containerView addSubview:fromView];
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            fromView.frame = CGRectMake(0, UIScreen.mainScreen.bounds.size.height, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height);
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
        return;
    }
    
    // 获取转场的源视图
    UIView *sourceView = [self.delegate transitionViewForSourceController];
    CGRect sourceFrame = [self transitionFrameWithView:sourceView];
    UIView *shadeView;
    if (self.hideSourceViewWhenTransition) {
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
    self.presentedTrasitionViewFrame = self.transitionView.frame;
    [containerView addSubview:self.transitionView];
    fromView.hidden = YES;
    
    // 执行转场
    [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        
        self.backGroundView.alpha = 0;
        if (!self.isInteractive) {
            if (!sourceView || CGRectEqualToRect(sourceFrame, CGRectZero)) {
                // 如果获取到的转场视图为空，则使用淡入淡出的动画效果
                self.transitionView.alpha = 0;
            } else {
                // 使用位移的动画效果
                self.transitionView.frame = sourceFrame;
            }
        }

    } completion:^(BOOL finished) {
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        sourceView.hidden = NO;
        [shadeView removeFromSuperview];
        if ([transitionContext transitionWasCancelled]) {
            fromView.hidden = NO;
            [self.transitionView removeFromSuperview];
            [self.backGroundView removeFromSuperview];
            [snapView removeFromSuperview];
            self.backGroundView = nil;
            self.transitionView = nil;

        } else {
//                MOLog(@"-------------------------- 完成转场:%@ --------------------------", toVC.view);
            [self.transitionView removeFromSuperview];
            [self.backGroundView removeFromSuperview];
            [snapView removeFromSuperview];
            self.backGroundView = nil;
            self.transitionView = nil;
        }
    }];
}


#pragma mark - dismiss视频的转场动画
- (void)dismissVideoWithAnimateTransition:(id<UIViewControllerContextTransitioning>)transitionContext fromView:(UIView *)fromView toView:(UIView *)toView snapView:(UIView *)snapView {
    
    UIView *containerView = transitionContext.containerView;
    UIView *transitionView = self.presentedTransitionView;

    // 如果获取的transitionView为空 或 定义了userDefaultAnimation，使用系统的默认转场
    if (!transitionView || self.userDefaultAnimation) {
        fromView.frame = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height);
        [containerView addSubview:fromView];
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            fromView.frame = CGRectMake(0, UIScreen.mainScreen.bounds.size.height, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height);
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
        return;
    }

    // 获取转场的源视图
    UIView *sourceView;
    CGRect sourceFrame;
    if (self.item.useCustomPlayer) {
        sourceView = transitionView;
        sourceFrame = self.trasitionViewOriginalFrame;
    } else {
        sourceView = [self.delegate transitionViewForSourceController];
        sourceFrame = [self transitionFrameWithView:sourceView];
        sourceView.hidden = self.hideSourceViewWhenTransition;
    }

    // 添加黑色背景
    [self addBackgroundViewToContainerView:containerView];

    // 获取视频播放的容器
    self.transitionView = self.presentedTransitionView;
    UIView *superView = self.transitionView.superview;
    NSInteger index = [superView.subviews indexOfObject:self.transitionView];
    self.presentedTrasitionViewFrame = self.transitionView.frame;
    
    // 将容器添加到containerView，保证转场过程中继续播放视频
//    [self.transitionView removeFromSuperview];
    [containerView addSubview:self.transitionView];
    fromView.hidden = YES;
    
    // 执行转场动画
    [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 options:0 animations:^{

        self.backGroundView.alpha = 0;
        if (!self.isInteractive) {
            if (!sourceView || CGRectEqualToRect(sourceFrame, CGRectZero)) {
                // 如果获取到的转场视图为空，则使用淡入淡出的动画效果
                self.transitionView.alpha = 0;
            } else {
                // 使用位移的动画效果
                self.transitionView.frame = sourceFrame;
            }
        }
        
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        sourceView.hidden = NO;
        [self.transitionView removeFromSuperview];
        [self.backGroundView removeFromSuperview];
        [snapView removeFromSuperview];
        if ([transitionContext transitionWasCancelled]) {
            fromView.hidden = NO;
            self.transitionView.frame = self.presentedTrasitionViewFrame;
            self.transitionView.alpha = 1;
            // 将视频播放容器 还原到转场后的容器
            [superView insertSubview:self.transitionView atIndex:index];
        } else {
            if (self.item.useCustomPlayer) {
                self.item.player.muted = YES;
                self.transitionView.tag = self.originalTag;
                [self.transitionSuperView addSubview:self.transitionView];
                self.transitionView.frame = self.originalFrameForTrasitionSuperView;
            }
        }
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
- (void)panAction:(UIScreenEdgePanGestureRecognizer *)pan {
    CGPoint point = [pan translationInView:[UIApplication sharedApplication].keyWindow];
    CGFloat progress = fabs(point.y / [UIApplication sharedApplication].keyWindow.bounds.size.height);
    progress = fmin(1, progress);
    static CGRect sourceFrame;
    static CGRect beginFrame;

    switch (pan.state) {
        case UIGestureRecognizerStateBegan: {
            self.isInteractive = YES;
            self.isDirectionDown = (point.y > 0);
            self.percentTransition = [[UIPercentDrivenInteractiveTransition alloc] init];
            [self.presentedVc dismissViewControllerAnimated:YES completion:nil];
            self.transitionView = self.presentedTransitionView;
            if (self.item.type == AFBrowserItemTypeImage) {
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
            sourceFrame = self.item.useCustomPlayer ? self.trasitionViewOriginalFrame : [self transitionFrameWithView:[self.delegate transitionViewForSourceController]];
        }
            break;
            
        case UIGestureRecognizerStateChanged: {
            self.backGroundView.alpha = fmax(1-progress*3, 0);
            CGFloat original_Y;
            if (self.isDirectionDown) {
                original_Y = fmax((UIScreen.mainScreen.bounds.size.height - self.imgView_H)/2, 0);
            } else {
                original_Y = fmax((UIScreen.mainScreen.bounds.size.height - self.imgView_H)/2, self.imgView_H - UIScreen.mainScreen.bounds.size.height);
            }
            CGFloat distance_W = (beginFrame.size.width - sourceFrame.size.width) * progress;
            CGFloat current_W = beginFrame.size.width - distance_W;
            CGFloat scale = current_W / beginFrame.size.width;
            self.transitionView.frame = CGRectMake(distance_W/2 + point.x + beginFrame.origin.x, original_Y + point.y, current_W, self.imgView_H * scale);
            [self.percentTransition updateInteractiveTransition:progress];
        }
            break;
            
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded:
            
            self.isInteractive = NO;
            if(progress > 0.2){
                [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:1 initialSpringVelocity:1 options:0 animations:^{
                    self.backGroundView.alpha = 0;
                    if (![self.delegate transitionViewForSourceController] && !self.item.useCustomPlayer) {
                        // 如果获取到的转场视图为空，则使用淡入淡出的动画效果
                        self.transitionView.alpha = 0;
                    } else {
                        // 使用位移的动画效果
                        self.transitionView.frame = sourceFrame;
                    }
                } completion:^(BOOL finished) {
                    [self.percentTransition finishInteractiveTransition];
                    self.percentTransition = nil;
                }];
            }else{
                self.backGroundView.alpha = 1;
                [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:1 initialSpringVelocity:1 options:0 animations:^{
                    self.transitionView.frame = self.presentedTrasitionViewFrame;
                } completion:^(BOOL finished) {
                    [self.percentTransition cancelInteractiveTransition];
                    self.percentTransition = nil;
                }];
            }
            
        default:
            break;
    }
}

- (void)startInteractiveTransition:(nonnull id<UIViewControllerContextTransitioning>)transitionContext {}



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
            resultFrame.origin.y = (frame.size.height - resultFrame.size.height)/2;
        } else {
            resultFrame.origin.x = (frame.size.width - resultFrame.size.width)/2;
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



@end
