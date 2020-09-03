//
//  AFBrowserCollectionViewCell.h
//  AFWorkSpace
//
//  Created by alfie on 2019/7/9.
//  Copyright © 2019 Alfie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AFPlayer.h"

@protocol AFBrowserCollectionViewCellDelegate <NSObject>

/** 单击事件 */
- (void)singleTapAction;


@end



@interface AFBrowserCollectionViewCell : UICollectionViewCell

/** 代理 */
@property (weak, nonatomic) id<AFBrowserCollectionViewCellDelegate> delegate;

@property (nonatomic, strong) UIScrollView  *scrollView;

@property (nonatomic, strong) UIImageView   *imageView;

/** 视频播放容器 */
@property (strong, nonatomic) UIView        *playerView;

/** 播放器 */
@property (strong, nonatomic) AFPlayer      *player;

//绑定数据
- (void)attachItem:(id)item atIndexPath:(NSIndexPath *)indexPath;


- (void)stopPlayer;


@end


