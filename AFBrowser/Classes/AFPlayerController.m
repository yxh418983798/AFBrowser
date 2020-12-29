//
//  AFPlayerController.m
//  AFBrowser
//
//  Created by alfie on 2020/12/26.
//

#import "AFPlayerController.h"
#import <objc/runtime.h>


@interface AFPlayerControllerProxy : NSObject
/** 播放器 */
@property (nonatomic, weak) AFPlayer            *player;
/** 是否target的代理 */
@property (nonatomic, assign) BOOL            isTargetProxy;
@end
@implementation AFPlayerControllerProxy
- (void)dealloc {
    NSLog(@"-------------------------- AFPlayerControllerProxy释放了:%@ --------------------------", self);
    [NSNotificationCenter.defaultCenter postNotificationName:@"AFPlayerControllerProxyDeallocNotification" object:self];
}
@end


@interface AFPlayerController ()

/** AFPlayerControllerProxy */
@property (nonatomic, weak) AFPlayerControllerProxy            *af_controllerProxy;

/** 播放器 */
@property (nonatomic, strong) AFPlayer            *player;

@end


@implementation AFPlayerController

#pragma mark - 构造方法，并绑定到某个对象
+ (instancetype)controllerWithTarget:(id)target {
    AFPlayerController *controller = AFPlayerController.new;
    controller.target = target;
    return controller;
}


#pragma mark - 绑定target
- (void)setTarget:(id)target {
    if (_target == target) return;
    
    NSMutableSet *originalProxyArray = objc_getAssociatedObject(_target, "AFPlayerControllerProxyArray");
    NSMutableSet *proxyArray = objc_getAssociatedObject(target, "AFPlayerControllerProxyArray");
    if (!proxyArray) {
        proxyArray = NSMutableSet.set;
        objc_setAssociatedObject(target, "AFPlayerControllerProxyArray", proxyArray, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    _target = target;
    if (target) {
        AFPlayerControllerProxy *proxy = self.af_controllerProxy;
        if (!proxy) {
            // 之前没有绑定过
            proxy = AFPlayerControllerProxy.new;
            self.af_controllerProxy = proxy;
            proxy.player = self.player;
            [proxyArray addObject:proxy];
            [NSNotificationCenter.defaultCenter addObserver:self.player selector:@selector(playerControllerProxyDeallocNotification:) name:@"AFPlayerControllerProxyDeallocNotification" object:proxy];
        } else {
            // 之前绑定过，直接添加到新的数组
            [proxyArray addObject:proxy];
            // 从旧的数组中移除
            if ([originalProxyArray containsObject:proxy]) {
                [originalProxyArray removeObject:proxy];
            }
        }
    }
}


#pragma mark - UI
- (AFPlayer *)player {
    if (!_player) {
        _player = [[AFPlayer alloc] initWithFrame:(CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height))];
    }
    return _player;
}


#pragma mark - 设置所有绑定target的播放器的活跃状态
+ (void)setPlayerActive:(BOOL)active forTarget:(id)target {
    if (target) {
        NSMutableArray *proxyArray = objc_getAssociatedObject(target, "AFPlayerControllerProxyArray");
        for (AFPlayerControllerProxy *proxy in proxyArray) {
            AFPlayer *player = proxy.player;
            player.isActive = active;
        }
    } else {
        if (active) {
            [AFPlayer resumeAllPlayer];
        } else {
            [AFPlayer pauseAllPlayer];
        }
    }
}


- (void)dealloc {
    NSLog(@"-------------------------- 销毁AFPlayerController:%@ --------------------------", self);
}
@end
