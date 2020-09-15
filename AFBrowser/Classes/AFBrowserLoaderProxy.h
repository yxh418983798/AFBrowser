//
//  AFBrowserLoaderProxy.h
//  AFBrowser
//
//  Created by alfie on 2020/9/2.
//

#import <Foundation/Foundation.h>
#import "AFBrowserLoaderDelegate.h"
#import "AFDownloader.h"

@interface AFBrowserLoaderProxy : NSObject <AFBrowserLoaderDelegate>

+ (instancetype)aVPlayerItemDidPlayToEndTimeNotificationWithTarget:(id)target selector:(SEL)selector;

@end


