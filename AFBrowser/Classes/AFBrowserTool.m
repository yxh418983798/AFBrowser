//
//  AFBrowserTool.m
//  AFBrowser
//
//  Created by alfie on 2020/12/21.
//

#import "AFBrowserTool.h"
#import "AFPlayer.h"
#import "AFBrowserItem.h"
#import <objc/runtime.h>

@interface AFBrowserTool ()

/** item */
@property (nonatomic, weak) AFBrowserItem       *item;

/** player */
@property (nonatomic, strong) AFPlayer          *player;

@end


@implementation AFBrowserTool

static NSUInteger MaxCount = 5; /// 最大存储数量
static dispatch_queue_t _toolQueue; /// 队列
static NSMutableArray <AFBrowserTool *> *_toolArray; /// 存储容器

#pragma mark - 生命周期
+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _toolArray = NSMutableArray.array;
        _toolQueue = dispatch_queue_create("com.Alfie.AFBrowserTool", DISPATCH_QUEUE_CONCURRENT);
    });
}

- (void)dealloc {
    [AFBrowserTool removeTool:self];
}


#pragma mark - 获取player
+ (AFPlayer *)playerWithItem:(AFBrowserItem *)item {
    if (!item || item.type != AFBrowserItemTypeVideo || !item.content) return [AFPlayer playerWithItem:item];
    
    AFBrowserTool *tool = objc_getAssociatedObject(item, "AFBrowserTool");
    if (!tool) {
        tool = AFBrowserTool.new;
        tool.item = item;
        tool.player = [AFPlayer playerWithItem:item];
        objc_setAssociatedObject(item, "AFBrowserTool", tool, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [self addTool:tool];
    return tool.player;
}


#pragma mark - 缓存tool
+ (void)addTool:(AFBrowserTool *)tool {
    if (!tool) return;
    dispatch_sync(_toolQueue, ^{
        if (![_toolArray containsObject:tool]) {
            // 数量超出限制的话，需要先清除数据
            while (_toolArray.count >= MaxCount) {
                dispatch_barrier_async(_toolQueue, ^{
                    [_toolArray removeObjectAtIndex:0];
                });
            }
            // 添加到数组进行缓存
            dispatch_barrier_async(_toolQueue, ^{
                [_toolArray addObject:tool];
            });
        }
    });
}


#pragma mark - 删除tool
+ (void)removeTool:(AFBrowserTool *)tool {
    if (!tool) return;
    dispatch_sync(_toolQueue, ^{
        if ([_toolArray containsObject:tool]) {
//            if (tool.item) objc_setAssociatedObject(tool.item, "AFBrowserTool", nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            // 清除数据
            dispatch_barrier_async(_toolQueue, ^{
                [_toolArray removeObject:tool];
            });
        }
    });
}


#pragma mark - 缓存player
//+ (void)cachePlayer:(AFPlayer *)player withItem:(AFBrowserItem *)item {
//    if (!item || !player || item.type != AFBrowserItemTypeVideo || !item.content) return;
//
//    AFBrowserTool *tool = objc_getAssociatedObject(item, "AFBrowserTool");
//    if (!tool) {
//        tool = AFBrowserTool.new;
//        tool.player = player;
//        tool.item = item;
//        objc_setAssociatedObject(item, "AFBrowserTool", tool, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
//    }
//    if (![self.toolArray containsObject:tool]) {
//        // 数量超出限制的话，需要先清除数据
//        while (self.toolArray.count >= MaxCount) {
//            [self.toolArray removeObjectAtIndex:0];
//        }
//        // 添加到数组进行缓存
//        [self.toolArray addObject:tool];
//    }
//}



///// 保存播放器的数组
//+ (NSPointerArray *)playerArray {
//    static NSPointerArray *_playerArray;
//    if (!_playerArray) {
//        _playerArray = [NSPointerArray pointerArrayWithOptions:NSPointerFunctionsWeakMemory];
//    }
//    return _playerArray;
//}
//
///// 添加到数组
//- (void)addToPlayerArray {
//    NSArray *playerArray = AFPlayer.playerArray.allObjects;
//    self.isActive = YES;
//    if (![playerArray containsObject:self]) {
//        // 没有在数组中，则直接添加在首位
//        [AFPlayer.playerArray insertPointer:(__bridge void *)(self) atIndex:0];
//        playerArray = AFPlayer.playerArray.allObjects;
//        // 添加后播放器后，检查是否超过了限制数量，如果超过，需要设置成不活跃状态，避免播放器数量太多造成解码失败
//        if (playerArray.count > MaxPlayer) {
//            for (int i = MaxPlayer; i < playerArray.count; i++) {
//                AFPlayer *player = playerArray[i];
//                player.isActive = NO;
//            }
//        }
//    } else {
//        // 如果已经存在，更新index到首位
//        if (AFPlayer.playerArray.count != playerArray.count) {
//            for (NSInteger i = AFPlayer.playerArray.count - 1; i >= 0 ; i--) {
//                if (![AFPlayer.playerArray pointerAtIndex:i]) {
//                    [AFPlayer.playerArray removePointerAtIndex:i];
//                }
//            }
//        }
//        NSInteger index = [AFPlayer.playerArray.allObjects indexOfObject:self];
//        if (index != 0) {
//            [AFPlayer.playerArray removePointerAtIndex:index];
//            [AFPlayer.playerArray insertPointer:(__bridge void *)(self) atIndex:0];
//        }
//    }
//}
//
///// 有播放器释放的时候，将等待中的不活跃播放器重新设置为活跃
//+ (void)resumeActiveExcludePlayer:(AFPlayer *)excludePlayer {
//    NSArray *playerArray = AFPlayer.playerArray.allObjects;
//    for (int i = 0; i < playerArray.count && i < MaxPlayer; i++) {
//        AFPlayer *player = playerArray[i];
//        if (player != excludePlayer) {
//            player.isActive = YES;
//        }
//    }
//}
//
//+ (AFPlayer *)cachePlayerWithItem:(AFBrowserItem *)item {
//    AFPlayer *result;
//    NSArray *array = AFPlayer.playerArray.allObjects;
//    for (AFPlayer *player in array) {
//        if ([player.item.content isEqualToString:item.content]) {
//            return player;
//        }
//    }
//    return nil;
//}




@end
