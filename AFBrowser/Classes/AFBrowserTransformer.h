//
//  AFBrowserTransformer.h
//  AFWorkSpace
//
//  Created by alfie on 2019/7/9.
//  Copyright © 2019 Alfie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFBrowserConfiguration.h"

@class AFBrowserItem;
@class AFBrowserTransformer;

@protocol AFBrowserTransformerDelegate <NSObject>

/// 源控制器的转场View
- (UIView *)transitionViewForSourceController;

/// 推出控制器的转场View
- (UIView *)transitionViewForPresentedController;

/// 推出控制器的转场View
- (UIView *)superViewForTransitionView:(UIView *)transitionView;

@end



@interface AFBrowserTransformer : NSObject <UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate, UIViewControllerInteractiveTransitioning>

/** 当前转场的item */
@property (nonatomic, strong) AFBrowserItem *item;

/** AFBrowserConfiguration */
@property (nonatomic, strong) AFBrowserConfiguration            *configuration;

/** 是否使用系统的默认转场 */
@property (nonatomic, assign) BOOL          userDefaultAnimation;

/** 代理 */
@property (weak, nonatomic) id <AFBrowserTransformerDelegate>  delegate;


/**
 * @brief 计算视图展示的frame
 *
 * @param size 图片或者转场视图的原大小
 */
+ (CGRect)displayFrameWithSize:(CGSize)size;

@end


