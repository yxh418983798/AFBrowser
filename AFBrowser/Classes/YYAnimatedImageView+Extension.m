//
//  YYAnimatedImageView+Extension.m
//  AFBrowser
//
//  Created by alfie on 2020/11/12.
//

#import "YYAnimatedImageView+Extension.h"
#import <objc/runtime.h>


@implementation YYAnimatedImageView (Extension)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        method_exchangeImplementations(class_getInstanceMethod([self class], @selector(af_displayLayer:)), class_getInstanceMethod([self class], @selector(displayLayer:)));
    });
}

- (void)af_displayLayer:(CALayer *)layer {
    Ivar ivar = class_getInstanceVariable(self.class, "_curFrame");
    UIImage *_curFrame = object_getIvar(self, ivar);
    if (_curFrame) {
        layer.contents = (__bridge id)_curFrame.CGImage;
    }else{
        if (@available(iOS 14.0, *)) {
            [super displayLayer:layer];
        }
    }
}

@end
