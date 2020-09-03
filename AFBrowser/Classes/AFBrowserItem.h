//
//  AFBrowserItem.h
//  MostOne
//
//  Created by alfie on 2019/11/5.
//  Copyright © 2019 MostOne. All rights reserved.
//

#import <Foundation/Foundation.h>

// 数据类型
typedef NS_ENUM(NSUInteger, AFBrowserItemType) {
    AFBrowserItemTypeImage,  // 图片
    AFBrowserItemTypeVideo,  // 视频
};

// 加载图片的状态
typedef NS_ENUM(NSUInteger, AFLoadImageStatus) {
    AFLoadImageStatusNone,      // 无图片
    AFLoadImageStatusCover,     // 已加载 缩略、封面图片
    AFLoadImageStatusOriginal,  // 已加载原始高清图片
};


@interface AFBrowserItem : NSObject

/**
 * @brief 构造图片数据
 *
 * @param item        图片数据，支持UIImage，NSString的url，NSURL）
 * @param coverImage  缩略图，可空，支持UIImage，NSString的url，NSURL）
 * @param identifier  标识符，可空，用于本地数据库分页读取数据时 标记关键数据的索引
 */
+ (instancetype)imageItem:(id)item coverImage:(id)coverImage identifier:(id)identifier;

/**
 * @brief 构造视频数据
 *
 * @param item        视频数据（支持NSString的url、URL）
 * @param coverImage  封面图，可空，支持UIImage，NSString的url，NSURL）
 * @param duration    视频时长，如果传0，则自动获取，会有延迟
 * @param identifier  标识符，可空，用于本地数据库分页读取数据时 标记关键数据的索引
 */
+ (instancetype)videoItem:(id)item coverImage:(id)coverImage duration:(CGFloat)duration identifier:(id)identifier;


/** 类型 */
@property (assign, nonatomic) AFBrowserItemType type;

/** item */
@property (strong, nonatomic) id                item;

/** 缩略图/封面图 */
@property (strong, nonatomic) id                coverImage;

/** identifier 标识符 */
@property (strong, nonatomic) id                identifier;

/** 视频时长 */
@property (assign, nonatomic) float             duration;

@end


