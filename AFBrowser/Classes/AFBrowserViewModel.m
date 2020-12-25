//
//  AFBrowserViewModel.m
//  AFBrowser
//
//  Created by alfie on 2020/12/25.
//

#import "AFBrowserViewModel.h"
#import "AFDownloader.h"

@implementation AFBrowserViewModel

+ (instancetype)viewModelWithItem:(AFBrowserItem *)item {
    AFBrowserViewModel *vm = AFBrowserViewModel.new;
    vm.item = item;
    return vm;
}

- (BOOL)validContent {
    if ([self.item.content isKindOfClass:NSString.class]) {
        return [(NSString *)self.item.content length] ;
    } else if ([self.item.content isKindOfClass:NSURL.class]) {
        return [(NSURL *)self.item.content absoluteString].length;
    } else if ([self.item.content isKindOfClass:NSData.class]) {
        return [(NSData *)self.item.content length];
    }
    return YES;
}

- (BOOL)validRemoteUrl {
    if ([self.item.content isKindOfClass:NSString.class]) {
        return [self.item.content hasPrefix:@"http"];
    } else if ([self.item.content isKindOfClass:NSURL.class]) {
        return [[(NSURL *)self.item.content absoluteString] hasPrefix:@"http"];
    }
    return NO;
}


#pragma mark - 返回已下载的视频或图片的本地地址
- (NSString *)filePath {
    NSString *url = [self.item.content isKindOfClass:NSString.class] ? self.item.content : [(NSURL *)self.item.content absoluteString];
    return [AFDownloader filePathWithUrl:url];
}



@end
