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


+ (instancetype)itemWithImage:(id)image coverImage:(id)coverImage width:(CGFloat)width height:(CGFloat)height size:(CGFloat)size {
    AFBrowserItem *browser = [AFBrowserItem new];
    browser.content = image;
    browser.coverImage = coverImage;
    browser.width = width;
    browser.height = height;
    browser.size = size;
    browser.type = AFBrowserItemTypeImage;
    return browser;
}


+ (instancetype)itemWithVideo:(id)video coverImage:(id)coverImage duration:(CGFloat)duration width:(CGFloat)width height:(CGFloat)height{
    AFBrowserItem *browser = [AFBrowserItem new];
    browser.content = video;
    browser.coverImage = coverImage;
    browser.type = AFBrowserItemTypeVideo;
    browser.duration = duration;
    browser.width = width;
    browser.height = height;
    return browser;
}



- (BOOL)validContent {
    if ([self.content isKindOfClass:NSString.class]) {
        return [(NSString *)self.content length] ;
    } else if ([self.content isKindOfClass:NSURL.class]) {
        return [(NSURL *)self.content absoluteString].length;
    } else if ([self.content isKindOfClass:NSData.class]) {
        return [(NSData *)self.content length];
    }
    return YES;
}


- (BOOL)validRemoteUrl {
    if ([self.content isKindOfClass:NSString.class]) {
        return [self.content hasPrefix:@"http"];
    } else if ([self.content isKindOfClass:NSURL.class]) {
        return [[(NSURL *)self.content absoluteString] hasPrefix:@"http"];
    }
    return NO;
}


- (BOOL)isEqual:(AFBrowserItem *)item {
    return [self.content isEqual:item.content] && [self.coverImage isEqual:item.coverImage];
}

@end
