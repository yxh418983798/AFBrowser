//
//  MWResponseModel.m
//  MWApi
//
//  Created by alfie on 2020/11/22.
//

#import "MWResponseModel.h"

@implementation MWResponseModel

+ (NSArray *)modelPropertyWhitelist {
    return @[@"code", @"msg", @"message", @"data"];
}

+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
             @"msg" : @[@"msg", @"message"]
             };
}


- (id)data {
    if ([_data isKindOfClass:NSNull.class]) {
        _data = nil;
    }
    return _data;
}

- (BOOL)hasNext {
    if (self.meta) return (self.meta.page_size * self.meta.currentPage < self.meta.total);
    if ([self.data isKindOfClass:[NSArray class]]) return ([(NSArray *)self.data count] > 0);
    return NO;
}

@end



@implementation MWResponseMetaModel

@end
