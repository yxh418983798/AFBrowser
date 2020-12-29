//
//  AFPlayerController.h
//  AFBrowser
//
//  Created by alfie on 2020/12/26.
//
//  管理播放器的类

#import <Foundation/Foundation.h>
#import "AFPlayer.h"

///// 播放器活跃属性
//typedef NS_ENUM(NSUInteger, AFPlayerActiveOption) {
//    AFPlayerActiveOptionAutoController,      /// 无图片
//    AFPlayerActiveOption,     /// 已加载 缩略、封面图片
//    AFLoadImageStatusOriginal,  /// 已加载原始高清图片
//};


@interface AFPlayerController : NSObject

/** target */
@property (nonatomic, weak) id            target;

/** 播放器 */
- (AFPlayer *)player;


/**
 * @brief 构造方法，并绑定到某个对象
 * @param target 绑定对象
 * @note  绑定效果：
 *        1、播放器的生命周期会绑定target，target释放后，播放器自动释放
 *        2、target也相当于一个分组，Controller可以通过target去控制这个分组的所有播放器
 */
+ (instancetype)controllerWithTarget:(id)target;


/**
 * @brief 设置所有绑定target的播放器的活跃状态
 *
 * @param target 被绑定的对象
 * @note  如果target为nil，则代表设置所有播放器的活跃状态
 * @note  active = false，会暂停所有播放器，这个暂停区别于播放器本身的暂停状态
 *        active = true，会恢复所有播放器，只有在设置非活跃状态之前处于播放状态的播放器，在恢复之后才会继续播放
 */
+ (void)setPlayerActive:(BOOL)active forTarget:(id)target;




@end


