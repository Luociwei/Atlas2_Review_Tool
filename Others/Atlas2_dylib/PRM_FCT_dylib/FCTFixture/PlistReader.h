//
//  PlistReader.h
//  FCTFixture
//
//  Created by Kim on 2021/8/15.
//  Copyright © 2021 PRM-JinHui.Huang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PlistReader : NSObject

@property (readonly) NSDictionary *rootContents;

//-(id)initWithFilePath: (NSString *)plistFilePath;

-(id)getItemsByKey: (NSString *)key;

@end

NS_ASSUME_NONNULL_END
