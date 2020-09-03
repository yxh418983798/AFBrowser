//
//  AFBrowserTransformer.h
//  AFWorkSpace
//
//  Created by alfie on 2019/7/9.
//  Copyright © 2019 Alfie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFBrowserItem.h"

@class AFBrowserTransformer;

@protocol AFBrowserTransformerDelegate <NSObject>

/// 源控制器的转场View
- (UIView *)transitionViewForSourceController;

/// 推出控制器的转场View
- (UIView *)transitionViewForPresentedController;

@end



@interface AFBrowserTransformer : NSObject <UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate, UIViewControllerInteractiveTransitioning>

/** 转场时，是否隐藏源视图 */
@property (assign, nonatomic) BOOL    hideSourceViewWhenTransition;

/** 是否使用系统的默认转场 */
@property (nonatomic, assign) BOOL    userDefaultAnimation;

/** AFBrowserItemType */
@property (assign, nonatomic) AFBrowserItemType type;

/** 代理 */
@property (weak, nonatomic) id <AFBrowserTransformerDelegate>     delegate;


@end


