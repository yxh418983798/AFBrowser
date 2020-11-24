//
//  MWRequestModel.m
//  MWApi
//
//  Created by alfie on 2020/11/24.
//

#import "MWRequestModel.h"
#import "MWApi.h"
@implementation MWRequestModel

- (NSUInteger)seq {
    if (_seq <= 0) {
        _seq = [MWApi.delegate makeSeq];
    }
    return _seq;
}


@end
