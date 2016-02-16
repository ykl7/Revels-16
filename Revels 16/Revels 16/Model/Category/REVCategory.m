//
//  REVCategory.m
//  Revels 16
//
//  Created by Avikant Saini on 2/2/16.
//  Copyright © 2016 LUG. All rights reserved.
//

#import "REVCategory.h"

@implementation REVCategory

- (instancetype)initWithDict:(id)dict {
	
	self = [super init];
	
	if (self) {
		
		if (dict && [dict isKindOfClass:[NSDictionary class]]) {
			
			if ([dict valueForKey:@"cname"])
				self.name = [NSString stringWithFormat:@"%@", dict[@"cname"]];
			
			if ([dict valueForKey:@"cdesc"])
				self.detail = [NSString stringWithFormat:@"%@", dict[@"cdesc"]];
			
			if ([dict valueForKey:@"imageName"])
				self.imageName = [NSString stringWithFormat:@"%@", dict[@"imageName"]];
			else
				self.imageName = [NSString stringWithFormat:@"%@", dict[@"cname"]];
//			
//			if ([dict valueForKey:@"cntctname"])
//				self.type = [NSString stringWithFormat:@"%@", dict[@"cntctname"]];
			
			if ([dict valueForKey:@"cid"])
				self.uid = [NSString stringWithFormat:@"%@", dict[@"cid"]];
			
		}
	}
	
	return self;
}

+ (NSMutableArray<REVCategory *> *)getArrayFromJSONData:(id)data {
	
	NSMutableArray <REVCategory *> *categories = [NSMutableArray new];
	
	if (data && [data isKindOfClass:[NSArray class]]) {
		for (NSDictionary *dict in data) {
			REVCategory *category = [[REVCategory alloc] initWithDict:dict];
			[categories addObject:category];
		}
	}
	
	// Optional sort
	[categories sortUsingComparator:^NSComparisonResult(REVCategory *obj1, REVCategory *obj2) {
		// Sort bu uid?
//		if (obj1.uid != 0 && obj2.uid != 0)
//			return (obj1.uid == obj2.uid)?NSOrderedSame:((obj1.uid < obj2.uid)?NSOrderedAscending:NSOrderedAscending);
		return [obj1.name compare:obj2.name];
	}];

	return categories;
}

@end
