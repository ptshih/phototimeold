//
//  CommentView.h
//  PhotoTime
//
//  Created by Peter Shih on 8/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSView.h"
#import "PSURLCacheImageView.h"

@interface CommentView : PSView {
  PSURLCacheImageView *_pictureView;
  UILabel *_messageLabel;
}

- (void)loadCommentsWithObject:(id)object;

@end
