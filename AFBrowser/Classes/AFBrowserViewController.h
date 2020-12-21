//
//  AFBrowserViewController.h
//  AFWorkSpace
//
//  Created by alfie on 2019/7/9.
//  Copyright © 2019 Alfie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AFBrowserLoaderDelegate.h"
#import "AFBrowserDelegate.h"
#import "AFPlayer.h"
#import "AFBrowserTool.h"
#import "AFBrowserItem.h"
#import "AFBrowserConfiguration.h"

@interface AFBrowserViewController : UIViewController

/**
 * @brief 设置浏览器的加载器代理
 *
 * @note  如果不设置的话，默认使用 SDWebImage 来加载图片
 * @note  对于加载视频，如果需要做本地缓存，建议设置代理并实现加载方法
 */
@property (nonatomic, class) Class <AFBrowserLoaderDelegate>   loaderProxy;

/** 配置 */
@property (nonatomic, strong) AFBrowserConfiguration *configuration;

/** 代理 */
@property (weak, nonatomic) id <AFBrowserDelegate>     delegate;


/**
 * @brief 获取指定index的item数据源
 * @note  如果缓存为空，会从代理方法中取
 */
- (AFBrowserItem *)itemAtIndex:(NSInteger)index;


/**
 * @brief 获取对应类型的方法，给外部调用
 *
 * @param action 方法类型
 */
- (SEL)selectorForAction:(AFBrowserAction)action;


/**
 * @brief 刷新数据
 *
 * @note  先更新外部的数据源，再刷新
 */
- (void)reloadData;


/**
 * @brief 弹出浏览器，开始浏览
 */
- (void)browse;


#pragma mark - 链式调用
/// 代理
- (AFBrowserViewController * (^)(id <AFBrowserDelegate>))makeDelegate;

/// 代理
- (AFBrowserViewController * (^)(AFBrowserConfiguration *))makeConfiguration;

@end


