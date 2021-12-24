//
//  FileDragView.m
//  DragDropDemo
//
//  Created by Louis Luo on 2021/6/24.
//  Copyright © 2021 Suncode. All rights reserved.

#import "FileDragView.h"

@implementation FileDragView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (void)awakeFromNib {
    
    [super awakeFromNib];
    
    [self registerForDraggedTypes:@[NSFilenamesPboardType]];
    
}

-(instancetype)init{
    self =[super init];
    if (self) {
//        [self registerForDraggedTypes:@[NSFilenamesPboardType]];
    }
    return self;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            self.stringValue = @"";
            
        });
    });
    return NSDragOperationNone;
}
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    
    NSLog(@"drag operation entered");
    
    NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];
    
    NSPasteboard *pboard = [sender draggingPasteboard];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            self.stringValue = @"";
            
        });
    });
    
    
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
        
        if (sourceDragMask & NSDragOperationLink) {
            return NSDragOperationLink;
        } else if (sourceDragMask & NSDragOperationCopy) {
            return NSDragOperationCopy;
        }
    }
    return NSDragOperationNone;
}


- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard *pboard = [sender draggingPasteboard];
    
    NSLog(@"drop now");
    
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
        
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        
        NSInteger numberOfFiles = [files count];
        
        if(numberOfFiles>0)
        {
//            NSString *filePath = [files objectAtIndex:0];
            
            //if(self.delegate){
               // [self.delegate didFinishDragWithFile:filePath];
            //}
            
            return YES;
            
        }

    }
    else{
        NSLog(@"pboard types(%@) not register!",[pboard types]);
    }
    return YES;
}

@end
