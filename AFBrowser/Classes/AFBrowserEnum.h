//
//  AFBrowserEnum.h
//  Pods
//
//  Created by alfie on 2020/12/17.
//

#ifndef AFBrowserEnum_h
#define AFBrowserEnum_h

/// 浏览模式
typedef NS_ENUM(NSUInteger, AFBrowserType){
    AFBrowserTypeDefault,  // 浏览模式，没有操作
    AFBrowserTypeDelete,   // 删除模式，可以删除图片
    //    AFBrowserTypeSelect,   // 选择模式，可以选中图片
};

/// 显示页码的方式
typedef NS_ENUM(NSUInteger, AFPageControlType){
    AFPageControlTypeNone,    // 不显示页码
    AFPageControlTypeCircle,  // 小圆点
    AFPageControlTypeText,    // 文字
};

/// 数据类型
typedef NS_ENUM(NSUInteger, AFBrowserItemType) {
    AFBrowserItemTypeImage,      /// 图片
    AFBrowserItemTypeVideo,      /// 视频
    AFBrowserItemTypeCustomView, /// 自定义视图
};

/// 播放器的播放方式
typedef NS_ENUM(NSUInteger, AFBrowserPlayOption){
    AFBrowserPlayOptionDefault,       /// 默认，刚进入浏览器时，如果是视频会自动播放，后续的翻页不会自动播放
    AFBrowserPlayOptionAutoPlay,      /// 自动播放，放大浏览和翻页切换视频的时候都会自动播放
    AFBrowserPlayOptionNeverAutoPlay, /// 不自动播放，只能通过 点击播放按钮 来播放视频
};

/// 播放器静音模式
typedef NS_ENUM(NSUInteger, AFPlayerMuteOption){
    AFPlayerMuteOptionNever,  // 不静音
    AFPlayerMuteOptionAlwaysButBrowser, // 浏览器中不静音，浏览器外静音播放
    AFPlayerMuteOptionAlways,   // 总是静音
};

/// 浏览器 屏幕旋转
typedef NS_ENUM(NSUInteger, AFBrowserRotation){
    AFBrowserRotationFollowSystem, /// 跟随系统
    AFBrowserRotationAlways,       /// 总是旋转
    AFBrowserRotationNever,        /// 不旋转
};

/// 翻页的方向
typedef NS_ENUM(NSUInteger, AFBrowserDirection){
    AFBrowserDirectionLeft,   /// 向左翻页
    AFBrowserDirectionRight,  /// 向右翻页
};

/// 提供给外部调用的事件类型
typedef NS_ENUM(NSUInteger, AFBrowserAction){
    AFBrowserActionDismiss,  /// dismiss事件
    AFBrowserActionDelete,   /// 删除事件
    AFBrowserActionReload,   /// 刷新事件
};

/// 图片类型
typedef NS_ENUM(NSUInteger, AFImageSizeType) {
    AFImageSizeTypeShort,    // 短图片
    AFImageSizeTypeNormal,   // 正常图片，不是长图
    AFImageSizeTypeLong,     // 不是很长的长图
    AFImageSizeTypeLongLong, // 很长的长图
};

/// 图片自适应方式
typedef NS_ENUM(NSUInteger, AFImageAdjustType) {
    AFImageAdjustTypeHeight,  // 自适应高度
    AFImageAdjustTypeWidth,   // 自适应宽度
    AFImageAdjustTypeSize,    // 自适应宽高
};

/// 浏览模式
typedef NS_ENUM(NSUInteger, AFBrowserTransitionStyle){
    AFBrowserTransitionStyleZoom,  // 默认的转场方式，前提是有实现代理方法：viewForTransitionAtIndex
    AFBrowserTransitionStyleSystem,  // 使用系统的转场方式
    AFBrowserTransitionStyleContinuousVideo,  // 转场过程不中断播放视频，前提：实现代理方法：viewForTransitionAtIndex，且返回AFPlayer
};

/// 加载图片的状态
typedef NS_ENUM(NSUInteger, AFLoadImageStatus) {
    AFLoadImageStatusNone,      /// 无图片
    AFLoadImageStatusCover,     /// 已加载 缩略、封面图片
    AFLoadImageStatusOriginal,  /// 已加载原始高清图片
};

/// 播放器转场状态
typedef NS_ENUM(NSUInteger, AFTransitionStatus) {
    AFTransitionStatusNormal,         /// 小屏
    AFTransitionStatusTransitioning, /// 转场中
    AFTransitionStatusPresented,    /// 全屏
};

/// 视频Item数据状态
typedef NS_ENUM(NSUInteger, AFBrowserVideoItemStatus) {
    AFBrowserVideoItemStatusDefault, ///< 初始状态
    AFBrowserVideoItemStatusPreloading, ///< 预加载状态，以低优先级插入队列并下载音频/视频，完成后保存到本地，属于用户无感知的下载状态（不展示Loading）
    AFBrowserVideoItemStatusLoading, ///< 主动触发的加载状态，以高优先级插入队列并下载音频/视频，完成后保存到本地，属于用户能感知的下载状态（展示Loading）
    AFBrowserVideoItemStatusFailed, ///< 下载失败或解码失败
    AFBrowserVideoItemStatusLoaded, ///< 下载完成
    AFBrowserVideoItemStatusPrepare, ///< 数据准备状态（解码中）
    AFBrowserVideoItemStatusPrepareDone, ///< 数据准备完成
};

/// 播放器状态
typedef NS_ENUM(NSUInteger, AFPlayerStatus) {
    AFPlayerStatusNormal,         /// 初始状态
    AFPlayerStatusLoading,         /// 加载中
    AFPlayerStatusPlay,         /// 播放中
    AFPlayerStatusBlock,         /// 黑名单
    AFPlayerStatusFailed,         /// 播放失败
};

/// 播放器恢复
typedef NS_ENUM(NSUInteger, AFPlayerResumeOption) {
    AFPlayerResumeOptionNone,         /// 不恢复
    AFPlayerResumeOptionAppBecomeActive, /// APP活跃
    AFPlayerResumeOptionBrowserAppeared, /// 浏览器出现
    AFPlayerResumeOptionOnNotification,
};

/// 播放器全局暂停原因
typedef NS_ENUM(NSUInteger, AFPlayerPauseAllReason) {
    AFPlayerPauseAllReasonNone,    ///< 默认，播放器可用状态
    AFPlayerPauseAllReasonByApplicationInactive,    ///< 应用处于不活跃状态，暂停所有播放器
    AFPlayerPauseAllReasonByApplicationBackground,    ///< 应用处于后台状态，暂停所有播放器
    AFPlayerPauseAllReasonBySystemCall, ///< 系统来电，暂停所有播放器
    AFPlayerPauseAllReasonByOther,    ///< 开发者手动暂停所有播放器，例如与音视频通话/直播间等业务冲突导致的播放器暂停
};


#endif /* AFBrowserEnum_h */
