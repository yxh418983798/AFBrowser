//
//  AFBrowserTransformer.h
//  AFWorkSpace
//
//  Created by alfie on 2019/7/9.
//  Copyright © 2019 Alfie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFBrowserConfiguration.h"

@class AFBrowserItem, AFBrowserTransformer;

@protocol AFBrowserTransformerDelegate <NSObject>

/// 源控制器的转场View
- (UIView *)transitionViewForSourceController;

/// 源控制器的转场View
- (UIImage *)transitionImageForSourceController;

/// 推出控制器的转场View
- (UIView *)transitionViewForPresentedController;

/// 推出控制器的转场View的父视图
- (UIView *)superViewForTransitionView:(UIView *)transitionView;

/// 获取当前展示的item
- (AFBrowserItem *)currentItem;

@end



@interface AFBrowserTransformer : NSObject <UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate, UIViewControllerInteractiveTransitioning>

/** AFBrowserConfiguration */
@property (nonatomic, strong) AFBrowserConfiguration  *configuration;

/** 代理 */
@property (weak, nonatomic) id <AFBrowserTransformerDelegate>  delegate;


/**
 * @brief 计算视图展示的frame
 *
 * @param size 图片或者转场视图的原大小
 */
+ (CGRect)displayFrameWithSize:(CGSize)size;

@end


