//
//  AFBrowserItem.m
//  MostOne
//
//  Created by alfie on 2019/11/5.
//  Copyright © 2019 MostOne. All rights reserved.
//

#import "AFBrowserItem.h"

@implementation AFBrowserItem

+ (instancetype)imageItem:(id)item coverImage:(id)coverImage identifier:(id)identifier {
    AFBrowserItem *browser = [AFBrowserItem new];
    browser.identifier = identifier;
    browser.item = item;
    browser.coverImage = coverImage;
    browser.type = AFBrowserItemTypeImage;
    return browser;
}


+ (instancetype)videoItem:(id)item coverImage:(id)coverImage duration:(CGFloat)duration identifier:(id)identifier {
    AFBrowserItem *browser = [AFBrowserItem new];
    browser.identifier = identifier;
    browser.item = item;
    browser.coverImage = coverImage;
    browser.type = AFBrowserItemTypeVideo;
    browser.duration = duration;
    return browser;
}




@end
