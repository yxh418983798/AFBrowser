//
//  MWRequestModel.h
//  MWApi
//
//  Created by alfie on 2020/11/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MWRequestModel : NSObject

/** seq */
@property (nonatomic, assign) NSUInteger        seq;

/** url */
@property (nonatomic, copy) NSString            *url;

/** data */
@property (nonatomic, strong) id                data;

@end

NS_ASSUME_NONNULL_END
