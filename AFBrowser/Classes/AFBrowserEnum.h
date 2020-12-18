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

/// 播放器的播放方式
typedef NS_ENUM(NSUInteger, AFBrowserPlayOption){
    AFBrowserPlayOptionDefault,       /// 默认，刚进入浏览器时，如果是视频会自动播放，后续的翻页不会自动播放
    AFBrowserPlayOptionAutoPlay,      /// 自动播放，放大浏览和翻页切换视频的时候都会自动播放
    AFBrowserPlayOptionNeverAutoPlay, /// 不自动播放，只能通过 点击播放按钮 来播放视频
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

typedef NS_ENUM(NSUInteger, AFImageSizeType) {
    AFImageSizeTypeShort,    // 短图片
    AFImageSizeTypeNormal,   // 正常图片，不是长图
    AFImageSizeTypeLong,     // 不是很长的长图
    AFImageSizeTypeLongLong, // 很长的长图
};

typedef NS_ENUM(NSUInteger, AFImageAdjustType) {
    AFImageAdjustTypeHeight,    // 自适应高度
    AFImageAdjustTypeWidth,   // 自适应宽度
    AFImageAdjustTypeSize,     // 自适应宽高
};


#endif /* AFBrowserEnum_h */
