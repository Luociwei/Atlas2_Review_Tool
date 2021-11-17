//
//  MyOutlineView.h
//  CPK_Tool
//
//  Created by Louis Luo on 2021/6/27.
//  Copyright © 2021 Suncode. All rights reserved.
//

#import <Cocoa/Cocoa.h>
//FOUNDATION_EXPORT NSString*  kDragOutlineViewTypeName;
//static NSString* const kDragOutlineViewTypeName = @"kDragOutlineViewTypeName";
NS_ASSUME_NONNULL_BEGIN

@interface OutlineView : NSOutlineView
@property(nonatomic,weak)NSMenu *treeMenu;
@end

NS_ASSUME_NONNULL_END
