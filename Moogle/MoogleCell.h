//
//  MoogleCell.h
//  Moogle
//
//  Created by Peter Shih on 2/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Constants.h"
#define SPACING_X 10.0
#define SPACING_Y 10.0
#define MARGIN_X 5.0
#define MARGIN_Y 5.0
enum {
  MoogleCellTypePlain = 0,
  MoogleCellTypeGrouped = 1
};
typedef uint32_t MoogleCellType;


@interface MoogleCell : UITableViewCell {
}

+ (MoogleCellType)cellType;
+ (CGFloat)rowWidth;
+ (CGFloat)rowHeight;
+ (CGFloat)variableRowHeightWithDictionary:(NSDictionary *)dictionary;
+ (CGFloat)variableRowHeightWithText:(NSString *)text andFontSize:(CGFloat)fontSize;

@end