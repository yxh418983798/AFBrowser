//
//  AFPlayerBottomBar.h
//  AFModule
//
//  Created by alfie on 2020/3/9.
//
//  播放器底部工具栏

#import <UIKit/UIKit.h>
#import "AFPlayerSlider.h"


@interface AFPlayerBottomBar : UIView

/** 背景图片 */
@property (strong, nonatomic) UIImageView        *backgroundView;

/** 播放按钮 */
@property (strong, nonatomic) UIButton           *playBtn;

/** 左侧时间 */
@property (strong, nonatomic) UILabel            *leftTimeLb;

/** 右侧时间 */
@property (strong, nonatomic) UILabel            *rightTimeLb;

/** AFPlayerSlider */
@property (strong, nonatomic) AFPlayerSlider     *slider;

/** 缓冲条 */
@property (strong, nonatomic) UIProgressView     *loadtimeView;

/** sliderValue */
@property (assign, nonatomic) float progress;

/** 缓冲progress */
@property (assign, nonatomic) float loadTimeProgress;

/** isSliderTouch */
@property (assign, nonatomic) BOOL  isSliderTouch;

/**
 * 更新进度
 *
 * @param currentTime   当前播放时间
 * @param durationTime  播放总时长
 */
- (void)updateProgressWithCurrentTime:(float)currentTime durationTime:(float)durationTime;


@end


