//
//  AFBrowserDelegate.h
//  AFBrowser
//
//  Created by alfie on 2020/9/3.
//

#import <Foundation/Foundation.h>

@class AFBrowserViewController;
@class AFBrowserItem;


/**
 * 浏览模式
 */
typedef NS_ENUM(NSUInteger, AFBrowserType){
    AFBrowserTypeDefault,  // 浏览模式，没有操作
//    AFBrowserTypeSelect,   // 选择模式，可以选中图片
    AFBrowserTypeDelete,   // 删除模式，可以删除图片
};


/**
 * 显示页码的方式
 */
typedef NS_ENUM(NSUInteger, AFPageControlType){
    AFPageControlTypeNone,    // 不显示页码
    AFPageControlTypeCircle,  // 小圆点
    AFPageControlTypeText,    // 文字
};


/**
 * 翻页的方向
 */
typedef NS_ENUM(NSUInteger, AFBrowserDirection){
    AFBrowserDirectionLeft,   // 向左翻页
    AFBrowserDirectionRight,  // 向右翻页
};


@protocol AFBrowserDelegate <NSObject>

@optional;


/// 返回转场的View，建议返回 UIImageView
- (UIView *)browser:(AFBrowserViewController *)browser viewForTransitionAtIndex:(NSInteger)index;


/// 获取 item
- (AFBrowserItem *)browser:(AFBrowserViewController *)browser itemForBrowserAtIndex:(NSInteger)index;


/**
 * @brief 删除事件
 * @note  该方法在用户点击删除按钮时调用，开发者可以在这里进行事件的预处理
 * 比如更新数据、弹窗提示用户是否确认删除等，当用户确认删除时，需要调用completionDelete()的block来通知browser删除数据并更新UI
 *
 * @param index 触发删除的index
 * @param completionDelete 删除的执行函数，
 */
- (void)browser:(AFBrowserViewController *)browser deleteActionAtIndex:(NSInteger)index completionDelete:(void (^)(void))completionDelete;


/**
 * 分页加载数据，每次浏览到第一个或最后一个Item时，自动调用该方法获取数据
 * 如果图片数据量很大，建议实现该协议来分页加载数据源，以提升性能
 * 实现该方法后，addItem：添加的数据 将会无效，AFBrowser会从该协议返回的数据来展示
 *
 * @param identifier 标识符
 * 一般是数据库表的主键或某个索引，也可以是自定义的其他数据类型，用于标记来获取对应的数据
 * 当第一次获取数据时，identifier是空的
 * 当向左翻页时，identifier返回当前数组第一个Item的identifier
 * 当向右翻页时，identifier返回当前数据最后一个Item的identifier
 *
 * @param direction  翻页方向
 * @result           返回一组AFBrowserItem实例
 */
- (NSArray<AFBrowserItem *> *)dataForItemWithIdentifier:(id)identifier direction:(AFBrowserDirection)direction;


@end

