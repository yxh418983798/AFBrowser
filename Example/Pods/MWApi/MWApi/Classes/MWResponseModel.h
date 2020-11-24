//
//  MWResponseModel.h
//  MWApi
//
//  Created by alfie on 2020/11/22.
//

#import <Foundation/Foundation.h>

@class MWResponseMetaModel;

@interface MWResponseModel : NSObject

/** 状态码 */
@property (assign, nonatomic) NSInteger           code;

/** 信息 */
@property (copy, nonatomic) NSString              *msg;

/** 返回数据 */
@property (strong, nonatomic) id                  data;

/** Meta 分页信息  默认是空的，如果需要转化，需要传入metaKeyPath */
@property (strong, nonatomic) MWResponseMetaModel *meta;

/** 错误 */
@property (strong, nonatomic) NSError             *error;

/** 是否有下一页，内部会自动根据Meta 或者 data 来判断是否有下一页 */
- (BOOL)hasNext;

@end


@interface MWResponseMetaModel : NSObject

/** 总数 */
@property (assign, nonatomic) NSInteger      total;

/** 当前页数 */
@property (assign, nonatomic) NSInteger      currentPage;

/** 每页数量 */
@property (assign, nonatomic) NSInteger      page_size;

@end
