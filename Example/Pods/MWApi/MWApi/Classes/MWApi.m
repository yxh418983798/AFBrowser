//
//  MWApi.m
//  MWApi
//
//  Created by alfie on 2020/11/22.
//

#import "MWApi.h"
#import <AFNetworking/AFHTTPSessionManager.h>
#import <YYModel/YYModel.h>
#import "MWRequestModel.h"

typedef void(^BlockWithCompletion)(id obj, NSError *error);
static NSString * const MONetworkingDataKey         = @"data";
static NSString * const APIMethodGET                = @"GET";
static NSString * const APIMethodPOST               = @"POST";
static NSString * const APIMethodDELETE             = @"DELETE";
static NSString * const APIMethodPUT                = @"PUT";
static NSString * const APIMethodPATCH              = @"PATCH";
static NSString * const APIMethodSOCKET             = @"SOCKET";
static NSString * const APIMethodGET_UNTILL_SOCKET  = @"GET_UNTILL_SOCKET";
static NSString * const APIMethodPOST_UNTILL_SOCKET = @"POST_UNTILL_SOCKET";
static NSTimeInterval _ignoreTime = 100.f; /// 过滤请求的时间临界点（距离上次请求的时间），单位毫秒
/// 非空字符串
#define MWNonNullString(string)   [string isKindOfClass:[NSString class]] ? (string.length ? string : @"") : ([string isKindOfClass:[NSNumber class]] ? [NSString stringWithFormat:@"%@", string] : @"")


@interface MWApi ()

/** 请求类 */
@property (strong, nonatomic) AFHTTPSessionManager  *manager;

/** 队列组事务 */
@property (strong, nonatomic) MWApiGroup            *apiGroup;

/** http url */
@property (copy, nonatomic) NSString                *httpUrl;

/** http请求的域名 */
@property (copy, nonatomic) NSString                *baseUrl;

/** 当前发送请求的完整url */
@property (copy, nonatomic) NSString                *url;

/** 请求头配置 */
@property (nonatomic, strong) NSDictionary          *headers;

/** 请求头ContentType */
@property (assign, nonatomic) MWApiContentType      contentType;

/** target */
@property (weak, nonatomic) UIViewController        *target;

/** hudOption */
@property (assign, nonatomic) MWProgressHudOption   hudOption;

/** 取消时机 */
@property (assign, nonatomic) MWApiCancelOption     cancelOption;

/** 重复请求的处理方式 */
@property (assign, nonatomic) MORepeatRequestOption repeatOption;

/** 转换模型类 */
@property (assign, nonatomic) Class                 modelClass;

/** 成功codes */
@property (nonatomic, strong) NSArray               *successCodes;

/** 转化模型的keyPath */
@property (copy, nonatomic) NSString                *keyPath;

/** 转化code的keyPath */
@property (copy, nonatomic) NSString                *codeKeyPath;

/// 转化msg的keyPath
@property (copy, nonatomic) NSString                *msgKeyPath;

/** 转化Meta的keyPath */
@property (copy, nonatomic) NSString                *metaKeyPath;

/** 超时时间 */
@property (assign, nonatomic) NSTimeInterval        timeoutInterval;

/** 进度回调 */
@property (copy, nonatomic) MWProgressBlock         progress;

/** 成功之前的回调 */
@property (copy, nonatomic) MWResponseBlock         willSuccess;

/** 成功之后的回调 */
@property (copy, nonatomic) MWResponseBlock         didSuccess;

/** 失败之前的回调 */
@property (copy, nonatomic) MWResponseBlock         willFailure;

/** 失败之后的回调 */
@property (copy, nonatomic) MWResponseBlock         didFailure;

/** 请求方式 */
@property (copy, nonatomic) NSString                *apiMethod;

/** 负责显示hud的View */
@property (weak, nonatomic) UIView                  *hudSuperView;

/** 请求任务 */
@property (weak, nonatomic) NSURLSessionDataTask    *task;

/** 记录是否从队列中移除，防止重复移除 */
@property (assign, nonatomic) BOOL                  isRemoveFromTask;

/** 记录任务是否取消 */
@property (assign, nonatomic) BOOL                  isCancel;

/** 记录请求是否收到响应 */
@property (nonatomic, assign) BOOL                  isResponse;

/** MOSocketRequestModel */
@property (nonatomic, strong) MWRequestModel        *socketReq;

@end


@implementation MWApi

#pragma mark - 构造
- (instancetype)init {
    self = [super init];
    if (self) {
        self.hudOption    = MWProgressHudOptionOnlyMessage;
        self.cancelOption = MWApiCancelOptionFollowTarget;
        self.repeatOption = MORepeatRequestOptionNone;
        self.timeoutInterval = 15.f;
    }
    return self;
}


#pragma mark - 设置代理
static id<MWApiDelegate> _delegate;
+ (void)setDelegate:(id<MWApiDelegate>)delegate {
    _delegate = delegate;
}

+ (id<MWApiDelegate>)delegate {
    return _delegate;
}


#pragma mark - Getter
- (AFHTTPSessionManager *)manager {
    if (!_manager) {
        _manager = [AFHTTPSessionManager new];
        _manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain", @"text/json", @"text/javascript", @"text/html", @"text/xml", @"application/xml", @"application/json", @"image/jpeg", @"image/png", nil];
        _manager.securityPolicy.allowInvalidCertificates = YES;
        _manager.securityPolicy.validatesDomainName = NO;
    }
    return _manager;
}

/// 存储api请求
+ (NSMutableArray *)apiTasks {
    static NSMutableArray *_apiTasks;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _apiTasks = [NSMutableArray array];
    });
    return _apiTasks;
}


#pragma mark - 配置 Api
/// 自定义请求头配置，如果不调用默认会自动配置token
- (instancetype)makeHeaders:(NSDictionary *)headers {
    self.headers = headers;
    return self;
}

/// 重复请求的过滤方式
- (instancetype)makeRepeatRequestOption:(MORepeatRequestOption)option{
    self.repeatOption = option;
    return self;
}

/// url
- (instancetype)makeUrl:(NSString *)url {
    self.httpUrl = url;
    return self;
}

/// 域名
- (instancetype)makeBaseUrl:(NSString *)baseUrl {
    self.baseUrl = baseUrl;
    return self;
}

/// 请求头ContentType
- (instancetype)makeApiContentType:(MWApiContentType)contentType {
    self.contentType = contentType;
    return self;
}

/// 参数
- (instancetype)makeParameters:(id)parameters {
    self.parameters = parameters;
    return self;
}

/// target
- (instancetype)makeTarget:(UIViewController *)target {
    self.target = target;
    return self;
}

// hudOption
- (instancetype)makeHudOption:(MWProgressHudOption)option {
    self.hudOption = option;
    return self;
}

// 取消时机
- (instancetype)makeCancelOption:(MWApiCancelOption)option {
    self.cancelOption = option;
    return self;
}

// 转换模型类
- (instancetype)makeModelClass:(Class)modelClass {
    self.modelClass = modelClass;
    return self;
}

// 设置请求成功的code识别数组，默认为200
- (instancetype)makeSuccessCodes:(NSArray <NSNumber *> *)codes {
    self.successCodes = codes;
    return self;
}

// 转换模型的keyPath，默认data
- (instancetype)makeKeyPath:(NSString *)keyPath {
    self.keyPath = keyPath;
    return self;
}

// 转化Code的keyPath，默认为@"code",  如果想转化的数据路径不是"code"，可以修改keyPath,比如@"resultCode"
- (instancetype)makeCodeKeyPath:(NSString *)keyPath {
    self.codeKeyPath = keyPath;
    return self;
}

// 转化msg的keyPath，默认为@"msg",  如果想转化的数据路径不是"msg"，可以修改keyPath,比如@"reason"
- (instancetype)makeMsgKeyPath:(NSString *)keyPath {
    self.msgKeyPath = keyPath;
    return self;
}

// 转化Meta的keyPath，默认是不会转化的, 如果获取Meta，需要传值，比如@"data.meta"
- (instancetype)makeMetaKeyPath:(NSString *)keyPath {
    self.metaKeyPath = keyPath;
    return self;
}

// 回调线程，默认为主线程
- (instancetype)makeCompletionQueue:(dispatch_queue_t)completionQueue {
    self.manager.completionQueue = completionQueue;
    return self;
}

// 设置超时时间，默认为15秒
- (instancetype)makeTimeoutInterval:(NSTimeInterval)timeoutInterval {
    self.timeoutInterval = timeoutInterval;
    return self;
}

// 进度回调
- (instancetype)makeProgressHandler:(MWProgressBlock)progress {
    self.progress = progress;
    return self;
}

// 成功回调
- (instancetype)makeSuccessHandler:(MWResponseBlock)success {
    self.success = success;
    return self;
}

// successHandler 之前执行的回调
- (instancetype)makeWillSuccessHandler:(MWResponseBlock)willSuccess {
    self.willSuccess = willSuccess;
    return self;
}

// successHandler 之后执行的回调
- (instancetype)makeDidSuccessHandler:(MWResponseBlock)didSuccess {
    self.didSuccess = didSuccess;
    return self;
}

/// 失败回调
- (instancetype)makeFailureHandler:(MWResponseBlock)failure {
    self.failure = failure;
    return self;
}

/// failureHandler 之前执行的回调
- (instancetype)makeWillFailureHandler:(MWResponseBlock)willFailure {
    self.willFailure = willFailure;
    return self;
}

/// failureHandler 之后执行的回调
- (instancetype)makeDidFailureHandler:(MWResponseBlock)didFailure {
    self.didFailure = didFailure;
    return self;
}

/// completion 完成回调，不管成功或失败都会走，completion的优先级 低于successHandler和failureHandler
- (instancetype)makeCompletionHandler:(MWResponseBlock)completion {
    self.completion = completion;
    return self;
}

/// 显示hud的View
- (UIView *)hudSuperView {
    if (!_hudSuperView) {
        if ([self.target isKindOfClass:UIViewController.class]) {
            _hudSuperView = [(UIViewController *)self.target view];
        } else {
            _hudSuperView = UIApplication.sharedApplication.keyWindow;
        }
    }
    return _hudSuperView;
}

// 成功回调处理
- (void)callbackSuccess:(id)data {
    if (self.willSuccess) {
        self.willSuccess(data);
    }
    if (self.success) {
        self.success(data);
    }
    if (self.didSuccess) {
        self.didSuccess(data);
    }
    if (self.completion) {
        self.completion(data);
    }
    if (self.apiGroup) {
        if ([self.apiGroup.responsesArray containsObject:self]) {
            [self.apiGroup.responsesArray replaceObjectAtIndex:[self.apiGroup.responsesArray indexOfObject:self] withObject:data];
        }
        [self removeFromTaskGroup];
    }
}

// 失败回调处理
- (void)callbackFailure:(id)data {
    if (self.willFailure) {
        self.willFailure(data);
    }
    if (self.failure) {
        self.failure(data);
    }
    if (self.didFailure) {
        self.didFailure(data);
    }
    if (self.completion) {
        self.completion(data);
    }
}

// 设置Socket的类型，默认为 MOSocketType_Normal
- (instancetype)makeReqModel:(id)req {
    if ([req isKindOfClass:MWRequestModel.class]) {
        self.socketReq = req;
    } else {
        self.socketReq = MWRequestModel.new;
        self.socketReq.data = req;
    }
    return self;
}


#pragma mark - 是否执行请求
- (BOOL)shouldRequst {
    if ([self.apiMethod containsString:APIMethodSOCKET]) {
        // Socket请求
        if (![MWApi.delegate isConnectedSocketForApi:self]) {
            self.url = [MWApi.delegate baseSocketUrlForApi:self];;
            [self didRequestFailureWithError:[NSError errorWithDomain:MWNonNullString(self.url) code:500 userInfo:@{@"message" : @"请求失败，socekt未连接"}] target:self.target];
            return NO;
        }

    } else {
        // HTTP 请求
        BOOL shouldAdd = NO;
        if (![self.httpUrl containsString:@"://"]) {
            NSString *baseUrl = self.baseUrl ?: [MWApi.delegate baseHttpUrlForApi:self];;
            NSString *url = self.httpUrl ?: @"";
            if (![baseUrl hasSuffix:@"/"] && ![url hasPrefix:@"/"]) shouldAdd = YES;
            self.url = [NSString stringWithFormat:@"%@%@%@", baseUrl, shouldAdd ? @"/" : @"", url];
        } else {
            self.url = MWNonNullString(self.httpUrl);
        }
    }
    return YES;
}


#pragma mark - 发送请求之前的处理
- (void)willRequest {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    });
    
    // HTTP请求配置
    if (![self.apiMethod containsString:APIMethodSOCKET]) {
        if (self.contentType == MWApiContentTypeJSON) {
            self.manager.requestSerializer = [AFJSONRequestSerializer serializer];
        }
        // 设置超时时间
        [self.manager.requestSerializer willChangeValueForKey:@"timeoutInterval"];
        self.manager.requestSerializer.timeoutInterval = self.timeoutInterval;
        [self.manager.requestSerializer didChangeValueForKey:@"timeoutInterval"];
        // 加载自定义请求头配置
        if (self.headers) {
            for (NSString *key in self.headers) {
                [self.manager.requestSerializer setValue:self.headers[key] forHTTPHeaderField:key];
            }
        }
        // 调用外部代理的处理
        if ([MWApi.delegate respondsToSelector:@selector(api:willRequestHTTPSessionManager:)]) {
            [MWApi.delegate api:self willRequestHTTPSessionManager:self.manager];
        }
    }
    
    // 释放管理
    if (self.cancelOption == MWApiCancelOptionFollowTarget && self.target) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(targetDidRelease) name:@"UIViewControllerDealloc" object:self.target];
    }
    
    self.apiGroup = MWApiGroup.currentGroup;
    if (self.apiGroup.group) {
        if (self.apiGroup.taskEnable) [self.apiGroup.responsesArray addObject:self];
        dispatch_group_enter(self.apiGroup.group);
    } else {
        if (self.hudOption & MWProgressHudOptionAll || self.hudOption & MWProgressHudOptionOnlyHud) {
            [MWApi.delegate showHudInView:self.hudSuperView];
        }
    }
}


#pragma mark - 请求失败处理，服务端返回数据失败
- (void)didRequestFailureWithError:(NSError *)error target:(UIViewController *)target {
    
    if (NSThread.isMainThread) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        });
    }
    
    if (self.isCancel) {
        [self logString:[NSString stringWithFormat:@"取消请求-- %@", self.url]];
        return;
    }
    if ([self.apiMethod isEqualToString:APIMethodGET_UNTILL_SOCKET] ) {
        [self logString:[NSString stringWithFormat:@"Socket请求失败，切换到Get请求"]];
        [self GET];
        return;;
    } else if ([self.apiMethod isEqualToString:APIMethodPOST_UNTILL_SOCKET]) {
        [self logString:[NSString stringWithFormat:@"Socket请求失败，切换到Post请求"]];
        [self POST];
        return;
    }
    
    if ([MWApi.delegate respondsToSelector:@selector(api:didRequestFailure:)]) {
        [MWApi.delegate api:self didRequestFailure:error];
    }
    

//    [MOXLogUntil LogNomalWithString:@"%@", [NSString stringWithFormat:@"\n{------Req FAIL - Socket \nURL--->%@\n ---seq:%ld -------op:%ld - param:--->%@\nerrorMsg--->%@ ----}\n", self.url,self.req.seq,self.req.reqType, self.parameters, error]];
    MWApiFailReason reason = AFNetworkReachabilityManager.sharedManager.isReachable ? MWApiFailReasonTimeout : MWApiFailReasonNetworkUnreachable;
    NSString *warnMsg = [MWApi.delegate messageForRequestFailReason:reason];
    MWResponseModel *responseModel = [MWResponseModel new];
    responseModel.error = error;
    responseModel.code = -1;
    responseModel.msg = warnMsg;
    
    error = [NSError errorWithDomain:[NSString stringWithFormat:@"%@", self.url] code:error.code userInfo:@{@"error" : warnMsg}];
    
    if (self.apiGroup.group) {
        if ([self.apiGroup.responsesArray containsObject:self]) {
            [self.apiGroup.responsesArray replaceObjectAtIndex:[self.apiGroup.responsesArray indexOfObject:self] withObject:responseModel];
        }
        self.apiGroup.error = error;
        [self callbackFailure:responseModel];
        [self removeFromTaskGroup];

    } else {
        
        if (self.hudOption == MWProgressHudOptionAll || self.hudOption == MWProgressHudOptionOnlyMessage) {
            if (NSThread.isMainThread) {
                [MWApi.delegate showMsg:warnMsg inView:self.hudSuperView completionHandle:^{
                    [self callbackFailure:responseModel];
                }];
            } else {
                [self callbackFailure:responseModel];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MWApi.delegate showMsg:warnMsg inView:self.hudSuperView completionHandle:nil];
                });
            }
        }
         
        else {
            [self callbackFailure:responseModel];
            dispatch_async(dispatch_get_main_queue(), ^{
                [MWApi.delegate hideHud];
            });
        }
    }
}

- (void)hideHUD {
    dispatch_async(dispatch_get_main_queue(), ^{
        [MWApi.delegate hideHud];
    });
}


#pragma mark - 请求返回成功处理 -- 请求成功或请求错误
- (void)didRequestSuccessWithResponseObject:(id)responseObject target:(UIViewController *)target {
    
    if (NSThread.isMainThread) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        });
    }
    
    // 数据解析成 MWResponseModel
    MWResponseModel *responseModel;
    if ([responseObject isKindOfClass:MWResponseModel.class]) {
        responseModel = responseObject;
    } else if ([responseObject isKindOfClass:NSString.class]) {
        NSString *responseString = [responseObject stringByReplacingOccurrencesOfString:@"\r\n" withString:@""];
        responseString = [responseString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        responseString = [responseString stringByReplacingOccurrencesOfString:@"\t" withString:@""];
        responseString = [responseString stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
        responseObject = [NSJSONSerialization JSONObjectWithData:[responseString dataUsingEncoding: NSUTF8StringEncoding] options:kNilOptions error:NULL];
    } else {
        responseModel = [MWResponseModel yy_modelWithJSON:responseObject];
    }

    if (self.msgKeyPath.length) {
        responseModel.msg = [responseObject valueForKey:self.msgKeyPath];
    }
    // 根据KeyPath，解析responseModel内的属性
    NSString *message = responseModel.msg;
    if (self.codeKeyPath.length) responseModel.code = [[responseObject valueForKey:self.codeKeyPath] intValue];
    NSInteger code = responseModel.code; // 请求的结果code
    BOOL isSuccess = NO; // 记录请求结果的code是否是成功的code
    if (self.successCodes.count) {
        for (NSNumber *successCode in self.successCodes) {
            if ([successCode isEqualToNumber:@(code)]) {
                isSuccess = YES;
                break;;
            }
        }
    } else {
        isSuccess = (code == 200) ? YES : NO;
    }
    
    //业务成功
    if (isSuccess) {
        if (![self.apiMethod containsString:APIMethodSOCKET]) {
            [self logString:[NSString stringWithFormat:@"\n请求成功：\nURL--->%@, 参数：\n%@\n返回数据：\n %@", self.url, self.parameters, [responseObject yy_modelToJSONObject]]];
        }
        
        // 隐藏HUD
        if (!self.apiGroup.group) {
           if (NSThread.isMainThread) {
               [self hideHUD];
           } else {
               [self performSelector:@selector(hideHUD) onThread:NSThread.mainThread withObject:nil waitUntilDone:YES];
           }
        }

        //转化meta
        if (self.metaKeyPath.length) {
           responseModel.meta = [MWResponseMetaModel yy_modelWithJSON:[self dictionary:responseObject valueForKeyPath:self.metaKeyPath]];
           if ([responseModel.meta isKindOfClass:[NSNull class]] || [responseModel.meta isEqual:NULL]) {
               responseModel.meta = nil;
           }
        }

        //不转化模型
        if (!self.modelClass) {
            if (![responseObject isKindOfClass:MWResponseModel.class]) {
                NSString *path = self.keyPath ?: MONetworkingDataKey;
                id modelData = path.length ? [self dictionary:responseObject valueForKeyPath:path] : responseObject;
                if ([modelData isKindOfClass:[NSString class]]) {
                    if ([modelData isEqualToString:@"null"]) {
                      modelData = nil;
                    }
                }
                responseModel.data = modelData;
            }
            [self callbackSuccess:responseModel];
        }

        // 自动转化模型
        else {
            id modelData;
            if ([responseObject isKindOfClass:MWResponseModel.class]) {
                modelData = [responseModel.data yy_modelToJSONObject];
            } else {
                NSString *path = self.keyPath ?: MONetworkingDataKey;
                modelData = path.length ? [self dictionary:responseObject valueForKeyPath:path] : responseObject;
            }
        
            // data为空
            if (!modelData) {
               [self callbackSuccess:responseModel];
               return;
            }

            // 字典类型
            if ([modelData isKindOfClass:[NSDictionary class]]) {
               responseModel.data = [self.modelClass yy_modelWithJSON:modelData];
               [self callbackSuccess:responseModel];
               return;
            }

            // 数组类型
            if ([modelData isKindOfClass:[NSArray class]]) {
               NSMutableArray *mutableArr = [NSMutableArray array];
               for (NSDictionary *dic in modelData) {
                   [mutableArr addObject:[self.modelClass yy_modelWithJSON:dic]];
               }
               responseModel.data = mutableArr;
               [self callbackSuccess:responseModel];
               return;
            }

            // 无法解析的其他类型
            if ([modelData isKindOfClass:[NSNull class]] || [modelData isEqual:NULL] || ([modelData isKindOfClass:[NSString class]] && [modelData isEqualToString:@"null"])) {
                [self logString:[NSString stringWithFormat:@"转化错误，data为null，responseObject：%@", responseObject]];
                modelData = nil;
                responseModel.data = modelData;
            } else {
                [self logString:[NSString stringWithFormat:@"转化错误，数据结构有问题，不是对象或数组，responseObject：%@", responseObject]];
            }
            [self callbackSuccess:responseModel];
        }
    }
    
    // 业务失败
    else {
        if (![self.apiMethod containsString:APIMethodSOCKET]) {
            [self logString:[NSString stringWithFormat:@"请求错误，URL:%@, 请求方式：%@\n参数：%@\n错误信息：%@", self.url, self.apiMethod, self.parameters, [responseObject yy_modelToJSONObject]]];
        }
        NSString *warnMsg = message.length ? message : [MWApi.delegate messageForRequestFailReason:MWApiFailReasonNetworkUnreachable];
        NSError *error = [NSError errorWithDomain:[NSString stringWithFormat:@"%@", self.url] code:code userInfo:@{@"error" : warnMsg}];
        responseModel.error = error;
        responseModel.msg = warnMsg;
        NSString *path = self.keyPath ?: MONetworkingDataKey;
        id modelData = path.length ? [self dictionary:responseObject valueForKeyPath:path] : responseObject;
        if ([responseModel.data isKindOfClass:[NSString class]] && [responseModel.data isEqualToString:@"null"]) {
            modelData = nil;
        }
        responseModel.data = modelData;
        
        // 交给外部代理 对业务错误进行的统一处理
        if ([MWApi.delegate respondsToSelector:@selector(api:didRequestError:)]) {
            [MWApi.delegate api:self didRequestError:responseModel];
        }
        
        //其他错误
        if (self.apiGroup.group) {
            if ([self.apiGroup.responsesArray containsObject:self]) {
                [self.apiGroup.responsesArray replaceObjectAtIndex:[self.apiGroup.responsesArray indexOfObject:self] withObject:responseModel];
            }
            self.apiGroup.error = error;
            [self callbackFailure:responseModel];
            [self removeFromTaskGroup];
        } else {
            if (self.hudOption & MWProgressHudOptionAll || self.hudOption & MWProgressHudOptionOnlyMessage) {
                if (NSThread.isMainThread) {
                    [MWApi.delegate showMsg:warnMsg inView:self.hudSuperView completionHandle:^{
                        [self callbackFailure:responseModel];
                    }];
                } else {
                    [self callbackFailure:responseModel];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [MWApi.delegate showMsg:warnMsg inView:self.hudSuperView completionHandle:nil];
                    });
                }
            }
            
            else {
                [self callbackFailure:responseModel];
                dispatch_async(dispatch_get_main_queue(), ^{
                   [MWApi.delegate hideHud];
                });
            }
        }
    }
}


#pragma mark -- 发起HTTP请求
// GET 请求
- (NSURLSessionDataTask *)GET {
    self.apiMethod = APIMethodGET;
    if (!self.shouldRequst) {
        return nil;
    }
    __weak typeof(self.target) weak_target = self.target;
    [self willRequest];
    NSURLSessionDataTask *task = [self.manager GET:self.url parameters:self.parameters progress:self.progress success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self didRequestSuccessWithResponseObject:responseObject target:weak_target];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self didRequestFailureWithError:error target:weak_target];
    }];
    _task = task;
    return task;
}


// POST 请求
- (NSURLSessionDataTask *)POST {
    self.apiMethod = APIMethodPOST;
    if (!self.shouldRequst) {
        return nil;
    }
    __weak typeof(self.target) weak_target = self.target;
    [self willRequest];
    NSURLSessionDataTask *task = [self.manager POST:self.url parameters:self.parameters progress:self.progress success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self didRequestSuccessWithResponseObject:responseObject target:weak_target];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self didRequestFailureWithError:error target:weak_target];
    }];
    _task = task;
    return task;
}


// DELETE 请求
- (NSURLSessionDataTask *)DELETE {
    self.apiMethod = APIMethodDELETE;
    if (!self.shouldRequst) {
        return nil;
    }
    __weak typeof(self.target) weak_target = self.target;
    [self willRequest];
    NSURLSessionDataTask *task = [self.manager DELETE:self.url parameters:self.parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self didRequestSuccessWithResponseObject:responseObject target:weak_target];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self didRequestFailureWithError:error target:weak_target];
    }];
    _task = task;
    return task;
}

// PATCH 请求
- (NSURLSessionDataTask *)PATCH {
    self.apiMethod = APIMethodPATCH;
    if (!self.shouldRequst) {
        return nil;
    }
    __weak typeof(self.target) weak_target = self.target;
    [self willRequest];
    NSURLSessionDataTask *task = [self.manager PATCH:self.url parameters:self.parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self didRequestSuccessWithResponseObject:responseObject target:weak_target];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self didRequestFailureWithError:error target:weak_target];
    }];
    _task = task;
    return task;
}

// PUT 请求
- (NSURLSessionDataTask *)PUT {
    self.apiMethod = APIMethodPUT;
    if (!self.shouldRequst) {
        return nil;
    }
    __weak typeof(self.target) weak_target = self.target;
    [self willRequest];
    NSURLSessionDataTask *task = [self.manager PUT:self.url parameters:self.parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self didRequestSuccessWithResponseObject:responseObject target:weak_target];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self didRequestFailureWithError:error target:weak_target];
    }];
    _task = task;
    return task;
}


#pragma mark - 发起SOCKET请求
- (void)SOCKET {
    self.apiMethod = APIMethodSOCKET;
    if (!self.shouldRequst) return;
    [self willRequest];
    [MWApi.apiTasks addObject:self];
    [MWApi.delegate api:self addSocketResponseNotificationWithReq:self.socketReq selector:@selector(receivedSocketResponse:)];
    [MWApi.delegate api:self socketRequestWithReq:self.socketReq];
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.timeoutInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (weakSelf && !weakSelf.isResponse) {
            [weakSelf didRequestFailureWithError:[NSError errorWithDomain:MWNonNullString(weakSelf.url) code:500 userInfo:@{@"message" : [MWApi.delegate messageForRequestFailReason:MWApiFailReasonTimeout]}] target:weakSelf.target];
            if ([MWApi.apiTasks containsObject:weakSelf]) {
                [MWApi.apiTasks removeObject:weakSelf];
            }
        }
    });
}

// 优先发送Socket请求，如果Socket请求失败（这里的失败是服务器或接口问题，不是业务错误），则调用HTTP的GET请求
- (void)GET_UNTILL_SOCKET {
    [self SOCKET];
    self.apiMethod = APIMethodGET_UNTILL_SOCKET;
}

// 优先发送Socket请求，如果Socket请求失败（这里的失败是服务器或接口问题，不是业务错误），则调用HTTP的POST请求
- (void)POST_UNTILL_SOCKET {
    [self SOCKET];
    self.apiMethod = APIMethodPOST_UNTILL_SOCKET;
}


#pragma mark - 收到Socket回应处理
- (void)receivedSocketResponse:(NSNotification *)notification {
    self.isResponse = YES;
    MWResponseModel *model = [MWApi.delegate api:self receivedSocketResponse:notification];
    [self didRequestSuccessWithResponseObject:model target:self.target];
    if ([MWApi.apiTasks containsObject:self]) {
        [MWApi.apiTasks removeObject:self];
    }
}


#pragma mark - 取消任务
- (void)cancelTask {
    self.isCancel = YES;
    if ([self.apiMethod containsString:APIMethodSOCKET]) { 
        self.isResponse = YES;
        [MWApi.delegate removeSocketResponseNotificationWithApi:self req:self.socketReq];
        [self didRequestFailureWithError:[NSError errorWithDomain:MWNonNullString(self.url) code:500 userInfo:@{@"message" : [MWApi.delegate messageForRequestFailReason:MWApiFailReasonTimeout]}] target:self.target];
        if ([MWApi.apiTasks containsObject:self]) {
            [MWApi.apiTasks removeObject:self];
        }

    } else {
        [_task cancel];
    }
    if (self.apiGroup) {
        if ([self.apiGroup.responsesArray containsObject:self]) {
            MWResponseModel *responseModel = [MWResponseModel new];
            responseModel.error = [NSError errorWithDomain:[NSString stringWithFormat:@"%@", self.url] code:666 userInfo:@{@"error" : [MWApi.delegate messageForRequestFailReason:MWApiFailReasonCancel]}];
            [self.apiGroup.responsesArray replaceObjectAtIndex:[self.apiGroup.responsesArray indexOfObject:self] withObject:responseModel];
        }
        [self removeFromTaskGroup];
    }
}

//从队列中移除
- (void)removeFromTaskGroup {
    static dispatch_semaphore_t semaphore;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        semaphore = dispatch_semaphore_create(1);
    });
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    if (!self.isRemoveFromTask) {
        self.isRemoveFromTask = YES;
        dispatch_group_leave(self.apiGroup.group);
    }
    dispatch_semaphore_signal(semaphore);
}

//target 被释放了，取消请求
- (void)targetDidRelease {
    [self cancelTask];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - 将日志回调出去
- (void)logString:(NSString *)string {
    if ([MWApi.delegate respondsToSelector:@selector(api:logString:)]) {
        [MWApi.delegate api:self logString:string];
    }
}


- (id)dictionary:(NSDictionary *)dictionary valueForKeyPath:(NSString *)keyPath {
    NSArray *keyArray = [keyPath componentsSeparatedByString:@"."];
    NSDictionary *subDic = dictionary;
    id result;
    for (int i = 0; i < keyArray.count; i++) {
        if (i == keyArray.count - 1) {
            if ([subDic isKindOfClass:NSDictionary.class]) {
                result = [subDic valueForKey:keyArray[i]];
            } else {
                result = nil;
            }
        } else {
            if ([subDic isKindOfClass:NSDictionary.class]) {
                subDic = [subDic valueForKey:keyArray[i]];
            } else {
                result = nil;
            }
        }
    }
    return result;
}

@end


