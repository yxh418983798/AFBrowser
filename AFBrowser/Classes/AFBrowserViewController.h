//
//  AFBrowserViewController.h
//  AFWorkSpace
//
//  Created by alfie on 2019/7/9.
//  Copyright © 2019 Alfie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AFBrowserItem.h"
#import "AFBrowserDelegate.h"

@interface AFBrowserViewController : UIViewController

/** 代理 */
@property (weak, nonatomic) id<AFBrowserDelegate>      delegate;

/** 当前选中的图片的index */
@property (assign, nonatomic) NSInteger                selectedIndex;

/** 浏览模式 */
@property (assign, nonatomic) AFBrowserType            browserType;

/** 页码显示类型，默认不显示 */
@property (nonatomic, assign) AFPageControlType        pageControlType;

/** 转场时，是否隐藏源视图，默认YES */
@property (assign, nonatomic) BOOL                     hideSourceViewWhenTransition;

/** 自定义参数 */
@property (nonatomic, strong) id                       userInfo;


/// 导航栏，用于开发者自定义导航栏样式 和 添加子视图
- (UIView *)toolBar;

/// 退出按钮
- (UIButton *)dismissBtn;

/// 删除按钮
- (UIButton *)deleteBtn;

/// 选择按钮
- (UIButton *)selectBtn;

/// 分页计数器
- (UIPageControl *)pageControl;

/// 分页计数（文本）
- (UILabel *)pageLabel;

/// 添加数据
- (void)addItem:(AFBrowserItem *)item;

/// 弹出浏览器，开始浏览
- (void)browse;


#pragma mark - 链式调用
- (AFBrowserViewController * (^)(id <AFBrowserDelegate>))makeDelegate;

- (AFBrowserViewController * (^)(NSUInteger))makeSelectedIndex;

- (AFBrowserViewController * (^)(AFBrowserType))makeBrowserType;

- (AFBrowserViewController * (^)(AFPageControlType))makePageControlType;

- (AFBrowserViewController * (^)(BOOL))makeHideSourceViewWhenTransition;

- (AFBrowserViewController * (^)(id))makeUserInfo;


@end


