//
//  MWApi.h
//  MWApi
//
//  Created by alfie on 2020/11/22.
//

#import <Foundation/Foundation.h>
#import "MWApiDelegate.h"
#import "MWResponseModel.h"
#import "MWApiGroup.h"

typedef void(^MWResponseBlock)(MWResponseModel *response);
typedef void(^MWProgressBlock)(NSProgress *progress);


/// HUD的展示方式
typedef NS_OPTIONS(NSInteger, MWProgressHudOption) {
    /// 什么都没有
    MWProgressHudOptionNone,
    /// 默认，只有错误提示，没有菊花
    MWProgressHudOptionOnlyMessage,
    /// 只有菊花，没有错误提示
    MWProgressHudOptionOnlyHud,
    /// 菊花 + 错误提示
    MWProgressHudOptionAll,
};
  
/// Http请求头的ContentType类型
typedef NS_OPTIONS(NSInteger, MWApiContentType) {
    MWApiContentTypeDefault,  /// 默认，application/x-www-form-urlencoded
    MWApiContentTypeJSON,     /// application/json
};

/// 请求的取消释放时机
typedef NS_OPTIONS(NSInteger, MWApiCancelOption) {
    MWApiCancelOptionFollowTarget,  /// 默认，跟随Target，如果Target被释放，请求会马上取消并释放，否则会等待请求结束再释放
    MWApiCancelOptionAutomatic,     /// 等待请求结束自动释放
};

/// 重复请求的过滤方式，默认不过滤
typedef NS_OPTIONS(NSInteger, MORepeatRequestOption) {
    MORepeatRequestOptionNone,             /// 不过滤请求
    MORepeatRequestOptionIgnoreNew,        /// 忽略新请求
    MORepeatRequestOptionIgnoreOld,        /// 取消旧请求，执行新请求
    MORepeatRequestOptionIgnoreShortTime,  /// 过滤短时间内(100ms内)发起的新请求
};


@interface MWApi : NSObject

/** 配置代理 */
@property (class) id <MWApiDelegate> delegate;


#pragma mark - 外部接口，写在外部的类中
/// target，UIViewController对象，用于管理API和HUD的生命周期，如果Target为空，则HUD会显示在Window上
- (instancetype)makeTarget:(id)target;

/// hud的父视图，如果Target是个控制器，则默认显示在target的View上，否则显示在window上
- (instancetype)makeHudSuperView:(UIView *)superView;

/// HUD的显示方式，如果当前请求在队列组事务（MOTaskTransaction）中，则该设置无效，需要外部自己管理HUD
- (instancetype)makeHudOption:(MWProgressHudOption)option;

/// 取消请求的时机，默认跟随Target，如果Target为空，则设置无效
- (instancetype)makeCancelOption:(MWApiCancelOption)option;

/// 转换模型类
- (instancetype)makeModelClass:(Class)modelClass;

/// 回调线程，默认为主线程
- (instancetype)makeCompletionQueue:(dispatch_queue_t)completionQueue;

/// 进度回调
- (instancetype)makeProgressHandler:(MWProgressBlock)progress;

/// successHandler 成功回调
- (instancetype)makeSuccessHandler:(MWResponseBlock)success;

/// failureHandler 失败回调
- (instancetype)makeFailureHandler:(MWResponseBlock)failure;

/// completion 完成回调，不管成功或失败都会走，completion的优先级 低于successHandler和failureHandler
- (instancetype)makeCompletionHandler:(MWResponseBlock)completion;


#pragma mark - 内部接口，写在MWApi的分类中

/** 成功回调 */
@property (copy, nonatomic) MWResponseBlock       success;

/** 失败回调 */
@property (copy, nonatomic) MWResponseBlock       failure;

/** 失败回调 */
@property (copy, nonatomic) MWResponseBlock       completion;

/** 参数，一般为字典 */
@property (strong, nonatomic) id                  parameters;

/// 自定义请求头配置，如果不调用默认会自动配置token
- (instancetype)makeHeaders:(NSDictionary *)headers;

/// 参数
- (instancetype)makeParameters:(id)parameters;

/// 域名，不设置时为默认域名
- (instancetype)makeBaseUrl:(NSString *)baseUrl;

/// HTTP请求的url，不需要拼接域名，会自动拼接
- (instancetype)makeUrl:(NSString *)url;

/// 请求头ContentType
- (instancetype)makeApiContentType:(MWApiContentType)contentType;

/// 设置请求成功的code识别数组，默认为200
/// 如果想设置 code等于0和200 时为成功，则调用 makeSuccessCodes:@[@(0), @(200)]
/// 如果请求的结果code是成功的code，会走SuccessHandle，否则会走FailureHandle
- (instancetype)makeSuccessCodes:(NSArray <NSNumber *> *)codes;

/// 转化Data模型的keyPath，默认为@"data",  如果想转化的数据路径不是"data"，可以修改keyPath,比如@"data.itemList"
- (instancetype)makeDataKeyPath:(NSString *)keyPath;

/// 转化Code的keyPath，默认为@"code",  如果想转化的数据路径不是"code"，可以修改keyPath,比如@"resultCode"
- (instancetype)makeCodeKeyPath:(NSString *)keyPath;

/// 转化msg的keyPath，默认为@"msg",  如果想转化的数据路径不是"msg"，可以修改keyPath,比如@"reason"
- (instancetype)makeMsgKeyPath:(NSString *)keyPath;

/// 转化Meta的keyPath，默认是不会转化的, 如果获取Meta，需要传值，比如@"data.meta"
- (instancetype)makeMetaKeyPath:(NSString *)keyPath;

/// 设置超时时间，默认为15秒
- (instancetype)makeTimeoutInterval:(NSTimeInterval)timeoutInterval;

/// successHandler 之前执行的回调
- (instancetype)makeWillSuccessHandler:(MWResponseBlock)willSuccess;

/// successHandler 之后执行的回调
- (instancetype)makeDidSuccessHandler:(MWResponseBlock)didSuccess;

/// failureHandler 之前执行的回调
- (instancetype)makeWillFailureHandler:(MWResponseBlock)willFailure;

/// failureHandler 之后执行的回调
- (instancetype)makeDidFailureHandler:(MWResponseBlock)didFailure;

/// 设置Socket的请求配置，由外部自定义模型
- (instancetype)makeReqModel:(id)req;


#pragma mark -- 发送请求，链式调用的时候一定要最后调用该方法

/// HTTP-GET
- (NSURLSessionDataTask *)GET;

/// HTTP-POST
- (NSURLSessionDataTask *)POST;

/// HTTP-DELETE
- (NSURLSessionDataTask *)DELETE;

/// HTTP-PATCH
- (NSURLSessionDataTask *)PATCH;

/// HTTP-PUT
- (NSURLSessionDataTask *)PUT;

/// Socket
- (void)SOCKET;

/// 优先发送Socket请求，如果Socket请求失败（这里的失败是服务器或接口问题，不是业务错误），则调用HTTP的GET请求
- (void)GET_UNTILL_SOCKET;

/// 优先发送Socket请求，如果Socket请求失败（这里的失败是服务器或接口问题，不是业务错误），则调用HTTP的POST请求
- (void)POST_UNTILL_SOCKET;


#pragma mark -- 取消任务
- (void)cancelTask;

@end

