//
//  MWApiGroup.m
//  MWApi
//
//  Created by alfie on 2020/11/23.
//

#import "MWApiGroup.h"
#import "MWResponseModel.h"
#import "MWApi.h"

@interface MWApiGroup ()

/** 回调的线程 */
@property (strong, nonatomic) dispatch_queue_t   queue;

/** 回调时机 */
@property (assign, nonatomic) MWApiGroupOption   option;

@end


@implementation MWApiGroup
static MWApiGroup *_currentGroup;

//当前事务对象
+ (instancetype)currentGroup {
    return _currentGroup;
}


- (dispatch_group_t)group {
    if (!_group) {
        _group = dispatch_group_create();
    }
    return _group;
}


- (NSMutableArray *)responsesArray {
    if (!_responsesArray) {
        _responsesArray = [NSMutableArray array];
    }
    return _responsesArray;
}


- (BOOL)taskEnable {
    return !(self.option == MWApiGroupOptionCancelRequestWhenError && self.error);
}


#pragma mark -- 开始
+ (void)start {
    [self startWithOption:(MWApiGroupOptionDefault) queue:nil];
}


+ (void)startWithOption:(MWApiGroupOption)option queue:(dispatch_queue_t)queue {
    
    _currentGroup = [MWApiGroup new];
    _currentGroup.option = option;
    _currentGroup.queue = queue ?: dispatch_get_main_queue();
    if (option == MWApiGroupOptionCancelRequestWhenError) {
        [_currentGroup addObserver:_currentGroup forKeyPath:@"error" options:(NSKeyValueObservingOptionNew) context:nil];
    }
}



#pragma mark -- 结束
+ (void)endWithCompletion:(void (^)(NSArray<MWResponseModel *> *, NSError *))completion {
    
    MWApiGroup *currentTransaction = _currentGroup;
    dispatch_group_notify(currentTransaction.group, currentTransaction.queue, ^{
       if (completion) {
           completion(currentTransaction.responsesArray, currentTransaction.error);
       }
    });
    _currentGroup = nil;
}



#pragma mark -- KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"error"]) {
        if (change[NSKeyValueChangeNewKey]) {
            //取消所有任务
            [self.responsesArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                MWApi *api = obj;
                if ([api isKindOfClass:[MWApi class]]) {
                    [api cancelTask];
                }
            }];
        }
    }
}



#pragma mark -- 移除观察者
- (void)dealloc {
    
    if (self.option == MWApiGroupOptionCancelRequestWhenError) [self removeObserver:self forKeyPath:@"error"];
}

@end
