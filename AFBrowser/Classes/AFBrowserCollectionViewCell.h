//
//  AFBrowserCollectionViewCell.h
//  AFWorkSpace
//
//  Created by alfie on 2019/7/9.
//  Copyright © 2019 Alfie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AFPlayer.h"

@class AFBrowserCollectionViewCell;

@protocol AFBrowserCollectionViewCellDelegate <NSObject>

/** 单击事件 */
- (void)singleTapAction;

/** 长按事件 */
- (void)longPressActionAtCollectionViewCell:(AFBrowserCollectionViewCell *)cell;

@end



@interface AFBrowserCollectionViewCell : UICollectionViewCell

/** 代理 */
@property (weak, nonatomic) id<AFBrowserCollectionViewCellDelegate> delegate;

@property (nonatomic, strong) UIScrollView  *scrollView;

@property (nonatomic, strong) UIImageView   *imageView;

/** 播放器 */
@property (strong, nonatomic) AFPlayer      *player;

// 绑定数据
- (void)attachItem:(id)item atIndexPath:(NSIndexPath *)indexPath;


- (void)stopPlayer;


@end


