//
//  AFBrowserLoaderDelegate.h
//  AFBrowser
//
//  Created by alfie on 2020/9/2.
//

#import <Foundation/Foundation.h>


@protocol AFBrowserLoaderDelegate <NSObject>


- (void)loadImage:(NSURL *)imageUrl completion:(void (^)(UIImage *))completion;


@end






