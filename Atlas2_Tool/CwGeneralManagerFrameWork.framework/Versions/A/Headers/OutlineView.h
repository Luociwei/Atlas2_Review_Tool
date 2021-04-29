//
//  MyOutlineView.h
//  CPK_Tool
//
//  Created by Louis Luo on 2020/6/27.
//  Copyright © 2020 Suncode. All rights reserved.
//

#import <Cocoa/Cocoa.h>
FOUNDATION_EXPORT NSString*  kDragOutlineViewTypeName;
//static NSString* const kDragOutlineViewTypeName = @"kDragOutlineViewTypeName";
NS_ASSUME_NONNULL_BEGIN

@interface OutlineView : NSOutlineView
@property(nonatomic,weak)NSMenu *treeMenu;
@end

NS_ASSUME_NONNULL_END
