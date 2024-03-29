//
//  AFBrowserCollectionViewCell.h
//  AFWorkSpace
//
//  Created by alfie on 2019/7/9.
//  Copyright © 2019 Alfie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AFPlayerView.h"

@class AFBrowserCollectionViewCell, AFBrowserItem, AFBrowserConfiguration;

@protocol AFBrowserCollectionViewCellDelegate <NSObject>

/** 单击事件 */
- (void)singleTapAction;

/** 退出事件 */
- (void)dismissActionAtCollectionViewCell:(AFBrowserCollectionViewCell *)cell;

/** 长按事件 */
- (void)longPressActionAtCollectionViewCell:(AFBrowserCollectionViewCell *)cell;

/** 查询图片缓存 */
- (UIImage *)browserCell:(AFBrowserCollectionViewCell *)cell hasImageCache:(id)content atIndex:(NSInteger)index;

/// 是否展示原图按钮
- (BOOL)browserCell:(AFBrowserCollectionViewCell *)cell shouldAutoLoadOriginalImageForItemAtIndex:(NSInteger)index;

@end

 

@interface AFBrowserCollectionViewCell : UICollectionViewCell

/** 代理 */
@property (weak, nonatomic) id<AFBrowserCollectionViewCellDelegate> delegate;

/** scrollView */
@property (nonatomic, strong) UIScrollView  *scrollView;

/** 图片 */
@property (nonatomic, strong) UIImageView   *imageView;

/** 播放器 */
@property (strong, nonatomic) AFPlayerView  *player;

/** 自定义视图 */
@property (nonatomic, weak) UIView        *customView;

/// 绑定数据
- (void)attachItem:(AFBrowserItem *)item configuration:(AFBrowserConfiguration *)configuration atIndexPath:(NSIndexPath *)indexPath;

/// 重置下自定义视图
- (void)removeCustomView;

/// 停止播放
- (void)stopPlayer;

@end


