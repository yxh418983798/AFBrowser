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
@property (nonatomic, weak) AFPlayerView            *player;
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
@property (nonatomic, strong) AFPlayerView            *player;

@end


@implementation AFPlayerController
static int playerCount = 0;

- (instancetype)init {
    if (self = [super init]) {
        playerCount ++;
        NSLog(@"-------------------------- 创建PlayerController：%d --------------------------", playerCount);
    }
    return self;
}

- (void)dealloc {
    playerCount --;
    NSLog(@"-------------------------- 释放PlayerController：%d --------------------------", playerCount);
}


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
- (AFPlayerView *)player {
    if (!_player) {
        _player = [[AFPlayerView alloc] initWithFrame:(CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height))];
//        objc_setAssociatedObject(_player, "AFPlayerController", self, OBJC_ASSOCIATION_ASSIGN);
    }
    return _player;
}


#pragma mark - 设置所有绑定target的播放器的活跃状态
+ (void)setPlayerActive:(BOOL)active forTarget:(id)target {
    if (target) {
        NSMutableArray *proxyArray = objc_getAssociatedObject(target, "AFPlayerControllerProxyArray");
        for (AFPlayerControllerProxy *proxy in proxyArray) {
            AFPlayerView *player = proxy.player;
//            id controller = objc_getAssociatedObject(player, "AFPlayerController");
//            if (player && controller) {
//                player.isActive = active;
//            } else {
//                NSLog(@"-------------------------- 发现错误！！ --------------------------");
//            }
        }
    } else {
        if (active) {
            [AFPlayerView resumeAllPlayer];
        } else {
            [AFPlayerView pauseAllPlayer];
        }
    }
}


@end
