//
//  AFBrowserCollectionViewCell.h
//  AFWorkSpace
//
//  Created by alfie on 2019/7/9.
//  Copyright © 2019 Alfie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AFPlayer.h"

@class AFBrowserCollectionViewCell, AFBrowserItem, AFBrowserConfiguration;

@protocol AFBrowserCollectionViewCellDelegate <NSObject>

/** 单击事件 */
- (void)singleTapAction;

/** 退出事件 */
- (void)dismissActionAtCollectionViewCell:(AFBrowserCollectionViewCell *)cell;

/** 长按事件 */
- (void)longPressActionAtCollectionViewCell:(AFBrowserCollectionViewCell *)cell;

@end

 

@interface AFBrowserCollectionViewCell : UICollectionViewCell

/** 代理 */
@property (weak, nonatomic) id<AFBrowserCollectionViewCellDelegate> delegate;

/** scrollView */
@property (nonatomic, strong) UIScrollView  *scrollView;

/** 图片 */
@property (nonatomic, strong) UIImageView   *imageView;

/** 播放器 */
@property (strong, nonatomic) AFPlayer      *player;

/// 绑定数据
- (void)attachItem:(AFBrowserItem *)item configuration:(AFBrowserConfiguration *)configuration atIndexPath:(NSIndexPath *)indexPath;

/// 重置下自定义视图
- (void)removeCustomView;

/// 停止播放
- (void)stopPlayer;

@end


