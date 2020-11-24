//
//  MWApiDelegate.h
//  MWApi
//
//  Created by alfie on 2020/11/22.
//

#import <Foundation/Foundation.h>

@class MWApi;
@class MWRequestModel;
@class MWResponseModel;
@class AFHTTPSessionManager;

/// 请求失败的原因
typedef NS_OPTIONS(NSInteger, MWApiFailReason) {
    MWApiFailReasonNetworkUnreachable,  /// 网络问题
    MWApiFailReasonTimeout,     /// 超时
    MWApiFailReasonCancel,     /// 主动取消
};


@protocol MWSocketReqDelegate <NSObject>

- (NSString *)url;

- (NSUInteger)seq;

@end



@protocol MWApiDelegate <NSObject>

#pragma mark - 必须实现的方法
/** 默认的Http请求域名 */
+ (NSString *)baseHttpUrlForApi:(MWApi *)api;

/** 默认的Socket请求域名 */
+ (NSString *)baseSocketUrlForApi:(MWApi *)api;

/** 请求失败的描述（提示语） */
+ (NSString *)messageForRequestFailReason:(MWApiFailReason)reason;

/** 展示Hud */
+ (void)showHudInView:(UIView *)view;

/** 展示提示信息 */
+ (void)showMsg:(NSString *)message inView:(UIView *)view completionHandle:(void (^)(void))completion;

/** 隐藏Hud */
+ (void)hideHud;


@optional;

#pragma mark - 如果有Socket请求，则以下方法必须实现
/**
 *  @brief 返回Socket是否已连接
 */
+ (BOOL)isConnectedSocketForApi:(MWApi *)api;


/**
 *  @brief 发起socket请求
 */
+ (void)api:(MWApi *)api socketRequestWithReq:(id)req;


/**
 *  @brief 处理Socket请求的响应
 */
+ (MWResponseModel *)api:(MWApi *)api receivedSocketResponse:(NSNotification *)notification;


/**
 *  @brief 为api添加Socket回调的通知
 */
+ (void)api:(MWApi *)api addSocketResponseNotificationWithReq:(MWRequestModel *)req selector:(SEL)selector;


/**
 *  @brief api移除Socket回调的通知
 */
+ (void)removeSocketResponseNotificationWithApi:(MWApi *)api req:(MWRequestModel *)req;

/** 构造seq */
+ (NSUInteger)makeSeq;


#pragma mark - 选择实现方法
/** 处理Api内部的日志，可用来输出日志和自定义上报日志 */
+ (void)api:(MWApi *)api logString:(NSString *)string;


/** 设置默认的data的解析路径，默认为"data" */
+ (NSString *)responseDataKeyPathForApi:(MWApi *)api;


/** 设置默认的meta的解析路径，默认为"meta" */
+ (NSString *)responseMetaKeyPathForApi:(MWApi *)api;


/**
 *  @brief 即将发起Http请求
 *  @note  可以在这里做一些默认的配置，比如请求头的默认配置，以及token的设置以及日志的输出等等
 */
+ (void)api:(MWApi *)api willRequestHTTPSessionManager:(AFHTTPSessionManager *)manager;


/** 请求失败的处理（非业务错误），服务器没有返回数据 */
+ (void)api:(MWApi *)api didRequestFailure:(NSError *)error;


/** 请求错误的处理（业务错误），服务器有返回对应的数据和code，可以在这里处理一些特殊的错误，如token失效等 */
+ (void)api:(MWApi *)api didRequestError:(MWResponseModel *)response;



@end

