//
//  AFBrowserItem.m
//  MostOne
//
//  Created by alfie on 2019/11/5.
//  Copyright © 2019 MostOne. All rights reserved.
//

#import "AFBrowserItem.h"

@interface AFBrowserItem ()

/** url */
@property (nonatomic, copy) NSString            *url;

@end


@implementation AFBrowserItem

+ (instancetype)itemWithImage:(id)image coverImage:(id)coverImage width:(CGFloat)width height:(CGFloat)height {
    AFBrowserItem *browser = [AFBrowserItem new];
    browser.item = image;
    browser.coverImage = coverImage;
    browser.width = width;
    browser.height = height;
    browser.type = AFBrowserItemTypeImage;
    return browser;
}


+ (instancetype)itemWithVideo:(id)video coverImage:(id)coverImage duration:(CGFloat)duration width:(CGFloat)width height:(CGFloat)height {
    AFBrowserItem *browser = [AFBrowserItem new];
    browser.item = video;
    browser.coverImage = coverImage;
    browser.type = AFBrowserItemTypeVideo;
    browser.duration = duration;
    browser.width = width;
    browser.height = height;
    return browser;
}


- (NSURL *)url {
    if (!_url) {
        if ([self.item isKindOfClass:NSString.class]) {
            _url = [NSURL URLWithString:(NSString *)self.item];
        } else if ([self.item isKindOfClass:NSURL.class]) {
            _url = self.item;
        }
    }
    return _url;
}


@end
