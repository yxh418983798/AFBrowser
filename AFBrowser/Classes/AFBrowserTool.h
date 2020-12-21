//
//  AFBrowserTool.h
//  AFBrowser
//
//  Created by alfie on 2020/12/21.
//
//  工具类

#import <Foundation/Foundation.h>

@class AFPlayer, AFBrowserItem;

@interface AFBrowserTool : NSObject

+ (AFPlayer *)playerWithItem:(AFBrowserItem *)item;


@end



