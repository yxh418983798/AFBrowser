//
//  AFBrowserItem.m
//  MostOne
//
//  Created by alfie on 2019/11/5.
//  Copyright © 2019 MostOne. All rights reserved.
//

#import "AFBrowserItem.h"
#import "AFDownloader.h"

@interface AFBrowserItem ()

/** url */
@property (nonatomic, copy) NSString            *url;

@end


@implementation AFBrowserItem

#pragma mark - 返回已下载的视频或图片的本地地址
- (NSString *)filePath {
    NSString *url = [self.content isKindOfClass:NSString.class] ? self.content : [(NSURL *)self.content absoluteString];
    return [AFDownloader filePathWithUrl:url];
}


+ (instancetype)itemWithImage:(id)image coverImage:(id)coverImage width:(CGFloat)width height:(CGFloat)height {
    AFBrowserItem *browser = [AFBrowserItem new];
    browser.content = image;
    browser.coverImage = coverImage;
    browser.width = width;
    browser.height = height;
    browser.type = AFBrowserItemTypeImage;
    return browser;
}


+ (instancetype)itemWithVideo:(id)video coverImage:(id)coverImage duration:(CGFloat)duration width:(CGFloat)width height:(CGFloat)height {
    AFBrowserItem *browser = [AFBrowserItem new];
    browser.content = video;
    browser.coverImage = coverImage;
    browser.type = AFBrowserItemTypeVideo;
    browser.duration = duration;
    browser.width = width;
    browser.height = height;
    return browser;
}




@end
