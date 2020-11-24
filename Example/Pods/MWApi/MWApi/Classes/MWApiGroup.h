//
//  MWApiGroup.h
//  MWApi
//
//  Created by alfie on 2020/11/23.
//
//  管理请求的队列组

#import <Foundation/Foundation.h>

// 队列回调的时机
typedef NS_OPTIONS(NSInteger, MWApiGroupOption) {
    MWApiGroupOptionDefault,                 // 默认，会等所有请求结束再走回调
    MWApiGroupOptionCancelRequestWhenError,  // 节约资源，一旦有一个请求失败，就会取消所有未结束的请求，并立即执行回调
};


@class MWResponseModel;

@interface MWApiGroup : NSObject


/** error，有多个错误时，error为最后一个的错误 */
@property (strong, nonatomic) NSError                 *error;

/** 队列组 */
@property (strong, nonatomic) dispatch_group_t        group;

/** 保存队列请求结果的数组 */
@property (strong, nonatomic) NSMutableArray          *responsesArray;


/**
 * @brief 开始任务
 */
+ (void)start;


/**
 * @brief 开始任务
 *
 * @param option 回调时机
 * @param queue  回调线程，nil时默认为主线程
 */
+ (void)startWithOption:(MWApiGroupOption)option queue:(dispatch_queue_t)queue;


/**
 *  @brief 结束任务 + 回调
 *
 *  @param completion 回调
 *  @note responsesArray：保存队列中所有的请求结果，数组中的顺序是按照发起请求的顺序进行排列
 *  @note error：如果error为空，则所有请求都是成功的，如果有请求失败，error对应的是最后一个失败的请求
 */
+ (void)endWithCompletion:(void (^)(NSArray <MWResponseModel *> *responsesArray, NSError *error))completion;


/**
 * @brief 获取当前的组
 */
+ (instancetype)currentGroup;


/**
 *  @brief 是否可以继续添加任务执行
 *  @note  当option为MWApiGroupOptionCancelRequestWhenError且出现错误请求时，此时不能添加任务
 */
- (BOOL)taskEnable;

@end


