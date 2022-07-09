//
//  AFBrowserItem.m
//  MostOne
//
//  Created by alfie on 2019/11/5.
//  Copyright © 2019 MostOne. All rights reserved.
//

#import "AFBrowserItem.h"
#import "AFDownloader.h"
#import <AVFoundation/AVFoundation.h>

@interface AFBrowserItem ()

/** url */
@property (nonatomic, copy) NSString            *url;

@end


@implementation AFBrowserItem

#pragma mark - 构造
/// 构造图片
+ (instancetype)itemWithImage:(id)image coverImage:(id)coverImage width:(CGFloat)width height:(CGFloat)height size:(CGFloat)size {
    AFBrowserItem *item = [AFBrowserItem new];
    item.content = image;
    item.coverImage = coverImage;
    item.width = width;
    item.height = height;
    item.size = size;
    item.type = AFBrowserItemTypeImage;
    return item;
}

/// 构造视频
+ (instancetype)itemWithVideo:(id)video coverImage:(id)coverImage duration:(CGFloat)duration width:(CGFloat)width height:(CGFloat)height{
    AFBrowserVideoItem *item = [AFBrowserVideoItem new];
    item.content = video;
    item.coverImage = coverImage;
    item.type = AFBrowserItemTypeVideo;
    item.duration = duration;
    item.width = width;
    item.height = height;
    return item;
}

/// 构造自定义视图
+ (instancetype)itemWithCustomView:(UIView *)view {
    AFBrowserCustomItem *item = AFBrowserCustomItem.new;
    item.type = AFBrowserItemTypeCustomView;
    item.view = view;
    return item;
}


#pragma mark - Getter
/// 返回已下载的视频或图片的本地地址
- (NSString *)filePath {
    NSString *url = [self.content isKindOfClass:NSString.class] ? self.content : [(NSURL *)self.content absoluteString];
    return [AFDownloader filePathWithUrl:url];
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



@implementation AFBrowserVideoItem

- (AVPlayerItem *)playerItem {
    if (!_playerItem && self.localPath) {
        NSString *url;
        if ([self.localPath hasPrefix:@"file://"]) {
            url = self.localPath;
        } else if ([self.localPath hasPrefix:@"/var/mobile/"]) {
            url = [NSString stringWithFormat:@"file://%@", self.localPath];
        }
        _playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:url]];
    }
    return _playerItem;
}

/// 获取下载完成后的本地路径
- (NSString *)localPath {
    NSString *url;
    if ([self.content isKindOfClass:NSString.class]) {
        url = self.content;
    } else if ([self.content isKindOfClass:NSURL.class]) {
        url = [(NSURL *)self.content absoluteString];
    }
    if (!_localPath && url.length) {
        if ([url containsString:NSHomeDirectory()]) {
            _localPath = url;
        } else if (![NSURL URLWithString:url].scheme) {
            _localPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), url];
        } else {
            _localPath = [AFDownloader filePathWithUrl:url];
        }
    }
    return _localPath;
}

/// 更新状态
- (void)updatePlayerStatus:(AFPlayerStatus)status {
    if (self.playerStatus == status) return;
    self.playerStatus = status;
}

- (void)updateItemStatus:(AFBrowserVideoItemStatus)itemStatus {
    if (self.itemStatus == itemStatus) return;
    switch (itemStatus) {
        case AFBrowserVideoItemStatusLoaded: {
            if (self.itemStatus < AFBrowserVideoItemStatusLoaded) {
                self.itemStatus = AFBrowserVideoItemStatusLoaded;
            }
        }
            break;
        default:
            self.itemStatus = itemStatus;
            break;
    }
}


@end


@implementation AFBrowserCustomItem




@end

