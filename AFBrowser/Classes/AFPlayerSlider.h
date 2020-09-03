//
//  AFPlayerSlider.h
//  AFModule
//
//  Created by alfie on 2020/3/9.
//

#import <UIKit/UIKit.h>

@class AFPlayerSlider;

@protocol AFPlayerSliderDelegate <NSObject>

- (void)slider:(AFPlayerSlider *)slider beginTouchWithValue:(float)value;

@end


@interface AFPlayerSlider : UISlider

/** 代理 */
@property (weak, nonatomic) id <AFPlayerSliderDelegate>            delegate;

@end


